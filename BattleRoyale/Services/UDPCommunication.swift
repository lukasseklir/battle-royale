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
        connection?.start(queue: .main)
    }

    /// Send a message to the configured peer
    func send(message: String) {
        guard let connection = connection else {
            print("❗️Connection not configured")
            return
        }

        let data = message.data(using: .utf8)!
        connection.send(content: data, completion: .contentProcessed({ error in
            if let error = error {
                print("❌ Send error: \(error)")
            } else {
                print("📤 Sent: \(message)")
            }
        }))
    }

    /// Starts listening for UDP messages on the specified port
    private func startListener() {
        do {
            let parameters = NWParameters.udp
            listener = try NWListener(using: parameters, on: receivePort)

            listener?.newConnectionHandler = { [weak self] newConnection in
                newConnection.start(queue: .main)
                self?.receive(on: newConnection)
            }

            listener?.start(queue: .main)
            print("📡 Listening on port \(receivePort)")
        } catch {
            print("❌ Failed to start listener: \(error)")
        }
    }

    /// Keep receiving data on the incoming connection
    private func receive(on connection: NWConnection) {
        connection.receiveMessage { (data, _, _, error) in
            if let error = error {
                print("❌ Receive error: \(error)")
            }

            if let data = data, let message = String(data: data, encoding: .utf8) {
                print("📥 Received: \(message)")
            } else {
                print("📥 Received data but couldn't decode.")
            }

            // Keep listening for more messages
            self.receive(on: connection)
        }
    }

    /// Returns the device’s local IP address on Wi-Fi
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

