//
//  MultipeerService.swift
//  BattleRoyale
//
//  Created by Lukas Seklir on 3/22/25.
//

import Foundation
import MultipeerConnectivity

protocol MultipeerServiceDelegate: AnyObject {
    func received(message: String, from peerID: MCPeerID)
    func peerDidConnect(_ peerID: MCPeerID)
    func peerDidDisconnect(_ peerID: MCPeerID)
}

final class MultipeerService: NSObject {
    private let serviceType = "chat-service"
    private let myPeerID = MCPeerID(displayName: UIDevice.current.name)
    private let session: MCSession
    private let advertiser: MCNearbyServiceAdvertiser
    private let browser: MCNearbyServiceBrowser

    weak var delegate: MultipeerServiceDelegate?

    override init() {
        session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
        advertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: nil, serviceType: serviceType)
        browser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: serviceType)

        super.init()

        session.delegate = self
        advertiser.delegate = self
        browser.delegate = self

        advertiser.startAdvertisingPeer()
        browser.startBrowsingForPeers()
    }

    func send(message: String) {
        guard !session.connectedPeers.isEmpty,
              let data = message.data(using: .utf8) else { return }

        try? session.send(data, toPeers: session.connectedPeers, with: .reliable)
    }

    deinit {
        advertiser.stopAdvertisingPeer()
        browser.stopBrowsingForPeers()
        session.disconnect()
    }
}

extension MultipeerService: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case .connected:
            delegate?.peerDidConnect(peerID)
        case .notConnected:
            delegate?.peerDidDisconnect(peerID)
        default:
            break
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        if let message = String(data: data, encoding: .utf8) {
            DispatchQueue.main.async {
                self.delegate?.received(message: message, from: peerID)
            }
        }
    }

    // Required empty stubs
    func session(_ session: MCSession, didReceive stream: InputStream, withName: String, fromPeer: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName: String, fromPeer: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName: String, fromPeer: MCPeerID, at: URL?, withError: Error?) {}
}

extension MultipeerService: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID,
                    withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(true, session)
    }
}

extension MultipeerService: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID,
                 withDiscoveryInfo info: [String : String]?) {
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {}
}
