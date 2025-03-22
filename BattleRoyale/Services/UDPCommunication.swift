//
//  UDPCommunication.swift
//  BattleRoyale
//
//  Created by Alain Zhiyanov on 3/22/25.
//

import Foundation
import Network

class UDPCommunication: ObservableObject {
    private var connection: NWConnection?
    private var listener: NWListener?
    private let receivePort: NWEndpoint.Port
    private var peerHost: NWEndpoint.Host?
    private var peerPort: NWEndpoint.Port?
    
    @Published var lastReceivedMessage: String = ""
    @Published var connectionState: String = "Not Connected"

    /// Initialize with the port you want this device to listen on
    init(receivePort: UInt16) {
        self.receivePort = NWEndpoint.Port(rawValue: receivePort)!
        startListener()
    }

    /// Set the IP and port of the other device you want to send messages to
    func configurePeer(ip: String, port: UInt16) {
        peerHost = NWEndpoint.Host(ip)
        peerPort = NWEndpoint.Port(rawValue: port)!

        connection = NWConnection(host: peerHost!, port: peerPort!, using: .udp)
        
        // Add state handling
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

    /// Send a message to the configured peer
    func send(message: String) {
        guard let connection = connection else {
            print("❗️Connection not configured")
            return
        }
        
        // Only send if connection is ready
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

    /// Starts listening for UDP messages on the specified port
    private func startListener() {
        do {
            let parameters = NWParameters.udp
            listener = try NWListener(using: parameters, on: receivePort)

            listener?.newConnectionHandler = { [weak self] newConnection in
                print("🔄 New connection received from: \(newConnection.endpoint)")
                newConnection.start(queue: .main)
                self?.receive(on: newConnection)
            }
            
            // Add state handling for listener
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

    /// Keep receiving data on the incoming connection
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
            } else if data != nil {
                print("📥 Received data but couldn't decode as UTF-8")
            }

            // Keep listening for more messages as long as connection is active
            if connection.state == .ready || connection.state == .preparing {
                self?.receive(on: connection)
            } else {
                print("⚠️ Connection no longer active, stopping receive loop")
            }
        }
    }
    
    // Wait for connection to be ready then send message
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

    /// Returns the device's local IP address on Wi-Fi
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
