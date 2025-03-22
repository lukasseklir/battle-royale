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

    init(receivePort: UInt16) {
        self.receivePort = NWEndpoint.Port(rawValue: receivePort)!
        startListener()
    }

    func configurePeer(ip: String, port: UInt16) {
        peerHost = NWEndpoint.Host(ip)
        peerPort = NWEndpoint.Port(rawValue: port)!
        
        connection = NWConnection(host: peerHost!, port: peerPort!, using: .udp)
        connection?.start(queue: .main)
    }

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

    private func receive(on connection: NWConnection) {
        connection.receiveMessage { (data, _, isComplete, error) in
            if let error = error {
                print("❌ Receive error: \(error)")
            }

            if let data = data, let message = String(data: data, encoding: .utf8) {
                print("📥 Received: \(message)")
            } else {
                print("📥 Received data but couldn’t decode.")
            }

            // 🔁 Keep listening for more messages
            self.receive(on: connection)
        }
    }
}

