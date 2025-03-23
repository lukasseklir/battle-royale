//
//  UDPCommunication.swift
//  BattleRoyale
//
//  Created by Alain Zhiyanov on 3/22/25.
//
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

    var onHitReceived: ((Double) -> Void)?

    init(receivePort: UInt16) {
        self.receivePort = NWEndpoint.Port(rawValue: receivePort)!
        super.init()
        startListener()
        publishService()
        startBrowsing()
    }

    func configurePeer(ip: String, port: UInt16) {
        peerHost = NWEndpoint.Host(ip)
        peerPort = NWEndpoint.Port(rawValue: port)

        connection = NWConnection(host: peerHost!, port: peerPort!, using: .udp)

        connection?.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                self?.connectionState = "Connected to \(ip):\(port)"
                print("✅ Connection ready to \(ip):\(port)")
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
            print("❗️Connection not configured")
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
                if message.hasPrefix("hit:") {
                    let damageString = message.replacingOccurrences(of: "hit:", with: "").trimmingCharacters(in: .whitespaces)
                    if let damage = Double(damageString) {
                        DispatchQueue.main.async {
                            self?.onHitReceived?(damage)
                        }
                    }
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
}
extension UDPCommunication: NetServiceBrowserDelegate, NetServiceDelegate {
    func publishService(name: String = UIDevice.current.name) {
        netService = NetService(domain: "local.", type: "_battle._udp.", name: name, port: Int32(receivePort.rawValue))
        netService?.delegate = self
        netService?.publish()
        print("📡 Published service as '\(name)' on port \(receivePort)")
    }

    func startBrowsing() {
        serviceBrowser = NetServiceBrowser()
        serviceBrowser?.delegate = self
        serviceBrowser?.searchForServices(ofType: "_battle._udp.", inDomain: "local.")
        print("🔍 Started browsing for peers...")
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        print("🔎 Found service: \(service.name)")
        discoveredServices.append(service)
        service.delegate = self
        service.resolve(withTimeout: 5)
    }

    func netServiceDidResolveAddress(_ service: NetService) {
        guard let addressData = service.addresses?.first else { return }

        addressData.withUnsafeBytes { (pointer: UnsafeRawBufferPointer) in
            let sockaddrPointer = pointer.baseAddress!.assumingMemoryBound(to: sockaddr_in.self)
            let ipCString = inet_ntoa(sockaddrPointer.pointee.sin_addr)
            let ipAddress = String(cString: ipCString!)
            let port = Int(UInt16(bigEndian: sockaddrPointer.pointee.sin_port))
            print("🌐 Resolved peer → \(ipAddress):\(port)")

            // Auto-configure peer
            self.configurePeer(ip: ipAddress, port: UInt16(port))
        }
    }
}

