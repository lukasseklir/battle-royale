import Foundation
import Network
import UIKit

class UDPCommunication: NSObject, ObservableObject {
    private var connection: NWConnection?
    private var listener: NWListener?
    private let receivePort: NWEndpoint.Port
    private var peerHost: NWEndpoint.Host?
    private var peerPort: NWEndpoint.Port?

    private var netService: NetService?
    private var serviceBrowser: NetServiceBrowser?
    private var discoveredServices: [NetService] = []

    @Published var lastReceivedMessage: String = ""
    @Published var connectionState: String = "Not Connected"
    @Published var discoveredPeers: [String] = [] // Track discovered peer names

    var onHitReceived: ((Double) -> Void)?
    var onPeerConfigured: ((String, UInt16) -> Void)? // Callback for when peer is configured

    init(receivePort: UInt16) {
        self.receivePort = NWEndpoint.Port(rawValue: receivePort)!
        super.init()
        startListener()
        publishService()
        startBrowsing()
    }

    func configurePeer(ip: String, port: UInt16) {
        print("🧩 Configuring peer → \(ip):\(port)")

        peerHost = NWEndpoint.Host(ip)
        peerPort = NWEndpoint.Port(rawValue: port)

        connection = NWConnection(host: peerHost!, port: peerPort!, using: .udp)

        connection?.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                self?.connectionState = "Connected to \(ip):\(port)"
                print("✅ Connection ready to \(ip):\(port)")
                DispatchQueue.main.async {
                    self?.onPeerConfigured?(ip, port) // Notify when peer is configured
                    // Send a test ping to verify the connection is working
                    self?.sendPing()
                }
            case .failed(let error):
                self?.connectionState = "Connection failed: \(error)"
                print("❌ Connection failed: \(error)")
            case .cancelled:
                self?.connectionState = "Connection cancelled"
                print("🚫 Connection cancelled")
            default:
                self?.connectionState = "Connection state: \(state)"
                print("ℹ️ Connection state changed: \(state)")
            }
        }

        connection?.start(queue: .main)
    }

    func send(message: String) {
        guard let connection = connection else {
            print("❗️Connection not configured — peer may not be discovered yet.")
            print("📌 Debug: peerHost = \(peerHost?.debugDescription ?? "nil"), peerPort = \(peerPort?.debugDescription ?? "nil")")
            print("📌 Debug: discovered services = \(discoveredServices.map { $0.name })")
            printDiscoveredServices()
            return
        }

        if connection.state == .ready {
            let data = message.data(using: .utf8)!
            connection.send(content: data, completion: .contentProcessed({ error in
                if let error = error {
                    print("❌ Send error: \(error)")
                } else {
                    print("📤 Sent: \(message)")
                }
            }))
        } else {
            print("⚠️ Connection not ready. Current state: \(connection.state)")
        }
    }

    // Add a ping function to test connectivity
    func sendPing() {
        print("🏓 Sending ping to test connection...")
        send(message: "ping")
    }

    // Add a function to print discovered services
    func printDiscoveredServices() {
        print("🔍 Currently discovered services: \(discoveredServices.map { $0.name })")
        if discoveredServices.isEmpty {
            print("⚠️ No services discovered yet. Make sure both devices are on the same network.")
        }
    }

    private func startListener() {
        do {
            let parameters = NWParameters.udp
            listener = try NWListener(using: parameters, on: receivePort)

            listener?.newConnectionHandler = { [weak self] newConnection in
                print("🔄 New connection received from: \(newConnection.endpoint)")
                newConnection.start(queue: .main)
                self?.receive(on: newConnection)
            }

            listener?.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    print("✅ Listener ready on port \(self.receivePort)")
                case .failed(let error):
                    print("❌ Listener failed: \(error)")
                case .cancelled:
                    print("🚫 Listener cancelled")
                default:
                    print("ℹ️ Listener state changed: \(state)")
                }
            }

            listener?.start(queue: .main)
            print("📡 Listening on port \(receivePort)")
        } catch {
            print("❌ Failed to start listener: \(error)")
        }
    }

    private func receive(on connection: NWConnection) {
        connection.receiveMessage { [weak self] (data, _, _, error) in
            if let error = error {
                print("❌ Receive error: \(error)")
            }

            if let data = data, let message = String(data: data, encoding: .utf8) {
                print("📥 Received: \(message)")
                DispatchQueue.main.async {
                    self?.lastReceivedMessage = message
                }
                
                // Handle specific message types
                if message.hasPrefix("hit:") {
                    let damageString = message.replacingOccurrences(of: "hit:", with: "").trimmingCharacters(in: .whitespaces)
                    if let damage = Double(damageString) {
                        DispatchQueue.main.async {
                            self?.onHitReceived?(damage)
                        }
                    }
                } else if message == "ping" {
                    // Respond to ping with pong
                    print("🏓 Received ping, sending pong...")
                    self?.send(message: "pong")
                } else if message == "pong" {
                    print("✅ Received pong - connection is working properly!")
                }
            } else if data != nil {
                print("📥 Received data but couldn't decode as UTF-8")
            }

            if connection.state == .ready || connection.state == .preparing {
                self?.receive(on: connection)
            } else {
                print("⚠️ Connection no longer active, stopping receive loop")
            }
        }
    }

    func sendWhenReady(message: String, timeout: TimeInterval = 5.0) {
        guard let connection = connection else {
            print("❗️Connection not configured")
            print("📌 Debug: Attempting to configure connection first...")
            // If we have discovered services but connection isn't configured, try to resolve them again
            if !discoveredServices.isEmpty {
                for service in discoveredServices {
                    if service.delegate == nil {
                        service.delegate = self
                        service.resolve(withTimeout: 5)
                    }
                }
                print("⏳ Waiting for service resolution...")
            } else {
                print("⚠️ No services discovered yet. Make sure both devices are on the same network.")
            }
            return
        }

        if connection.state == .ready {
            send(message: message)
            return
        }

        print("⏳ Waiting for connection to be ready...")
        let deadline = DispatchTime.now() + timeout

        func checkAndSend() {
            if connection.state == .ready {
                send(message: message)
            } else if DispatchTime.now() < deadline {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    checkAndSend()
                }
            } else {
                print("⏱️ Timeout waiting for connection to be ready")
                print("📌 Debug: Connection state at timeout: \(String(describing: self.connection?.state))")
            }
        }

        checkAndSend()
    }

    var localIPAddress: String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?

        if getifaddrs(&ifaddr) == 0 {
            var ptr = ifaddr
            while ptr != nil {
                defer { ptr = ptr?.pointee.ifa_next }

                let interface = ptr!.pointee
                let addrFamily = interface.ifa_addr.pointee.sa_family
                let name = String(cString: interface.ifa_name)

                if addrFamily == UInt8(AF_INET), name == "en0" {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface.ifa_addr,
                                socklen_t(interface.ifa_addr.pointee.sa_len),
                                &hostname,
                                socklen_t(hostname.count),
                                nil,
                                socklen_t(0),
                                NI_NUMERICHOST)
                    address = String(cString: hostname)
                    break
                }
            }
            freeifaddrs(ifaddr)
        }

        return address
    }
    
    // Function to check network connectivity
    func checkNetworkStatus() {
        print("🔍 Network Status Check:")
        if let localIP = localIPAddress {
            print("✅ Local IP Address: \(localIP)")
        } else {
            print("❌ Could not determine local IP address")
        }
        
        print("🔍 Discovered services: \(discoveredServices.map { $0.name })")
        print("🔍 Listener state: \(String(describing: listener?.state))")
        print("🔍 Connection state: \(String(describing: connection?.state))")
    }
}

extension UDPCommunication: NetServiceBrowserDelegate, NetServiceDelegate {
    func publishService(name: String = UIDevice.current.name) {
        netService = NetService(domain: "local.", type: "_battle._udp.", name: name, port: Int32(receivePort.rawValue))
        netService?.delegate = self
        netService?.publish()
        print("📡 Published service as '\(name)' on port \(receivePort)")
        
        // Add a delay and check if the service was published successfully
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            if self?.netService?.port == -1 {
                print("⚠️ Service may not have published correctly. Check Info.plist permissions.")
            } else {
                print("✅ Service published successfully on port: \(self?.netService?.port ?? -1)")
            }
        }
    }

    func startBrowsing() {
        serviceBrowser = NetServiceBrowser()
        serviceBrowser?.delegate = self
        serviceBrowser?.searchForServices(ofType: "_battle._udp.", inDomain: "local.")
        print("🔍 Started browsing for peers...")
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        if service.name == UIDevice.current.name {
            print("🚫 Ignored own service: \(service.name)")
            return
        }

        print("🔎 Found peer service: \(service.name)")
        discoveredServices.append(service)
        DispatchQueue.main.async {
            self.discoveredPeers = self.discoveredServices.map { $0.name }
        }
        service.delegate = self
        service.resolve(withTimeout: 5)
    }
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
        print("🚫 Service removed: \(service.name)")
        if let index = discoveredServices.firstIndex(where: { $0.name == service.name }) {
            discoveredServices.remove(at: index)
            
            DispatchQueue.main.async {
                self.discoveredPeers = self.discoveredServices.map { $0.name }
            }
        }
    }
    
    func netServiceBrowserDidStopSearch(_ browser: NetServiceBrowser) {
        print("🛑 Service browser stopped searching")
    }
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String : NSNumber]) {
        print("❌ Service browser failed to search: \(errorDict)")
    }

    func netServiceDidResolveAddress(_ service: NetService) {
        guard let addressData = service.addresses?.first else {
            print("❌ Could not resolve address for service: \(service.name)")
            return
        }

        addressData.withUnsafeBytes { (pointer: UnsafeRawBufferPointer) in
            let sockaddrPointer = pointer.baseAddress!.assumingMemoryBound(to: sockaddr_in.self)
            let ipCString = inet_ntoa(sockaddrPointer.pointee.sin_addr)
            let ipAddress = String(cString: ipCString!)
            let port = Int(UInt16(bigEndian: sockaddrPointer.pointee.sin_port))

            print("🌐 Resolved peer → \(ipAddress):\(port)")

            self.configurePeer(ip: ipAddress, port: UInt16(port))
        }
    }
    
    func netService(_ sender: NetService, didNotResolve errorDict: [String : NSNumber]) {
        print("❌ Failed to resolve service: \(sender.name), error: \(errorDict)")
    }
    
    func netServiceDidPublish(_ sender: NetService) {
        print("✅ Successfully published service: \(sender.name) on port \(sender.port)")
    }
    
    func netService(_ sender: NetService, didNotPublish errorDict: [String : NSNumber]) {
        print("❌ Failed to publish service: \(sender.name), error: \(errorDict)")
    }
}
