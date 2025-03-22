//
//  InitialViewController.swift
//  BattleRoyale
//
//  Created by Lukas Seklir on 3/22/25.
//

import UIKit
import Network  // Imported to use NWBrowser for triggering the prompt

class InitialViewController: UIViewController {

    let titleLabel = UILabel.createLabel(fontSize: 40, color: .white, thickness: .heavy, numLines: 0, text: "Let's\nBattle")
    let getStartedButton = StandardButton(title: "Get Started", tintColor: .systemIndigo, backgroundColor: .white)
    
    var udp: UDPCommunication?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Trigger the local network permission prompt early
        triggerLocalNetworkPrompt()
        
        // Initialize and use UDPCommunication
        udp = UDPCommunication(receivePort: 9999)
        
        // Configure the peer with your friend's IP
        udp?.configurePeer(ip: "206.87.217.87", port: 8888)
        
        // Wait for connection to be ready before sending
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.udp?.sendWhenReady(message: "💥 Bullet fired from device!")
        }
        
        if let ip = udp?.localIPAddress {
            print("📱 My IP address: \(ip)")
        } else {
            print("⚠️ No IP address found")
        }
        
        setupUI()
    }
    
    /// Uses NWBrowser to trigger the local network permission prompt.
    /// This browser does not need to find any services.
    func triggerLocalNetworkPrompt() {
        // Create a dummy Bonjour browser to prompt for local network access.
        let browser = NWBrowser(for: .bonjour(type: "_localservice._udp", domain: nil), using: .udp)
        browser.stateUpdateHandler = { state in
            print("NWBrowser state: \(state)")
        }
        browser.start(queue: .main)
    }
    
    func setupUI() {
        self.view.backgroundColor = .systemIndigo
        let stackView = UIStackView.createStackView(axis: .vertical, distribution: .equalSpacing)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: self.view.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 32),
            stackView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -32),
            stackView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor)
        ])
        
        let topView = UIView()
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        topView.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: topView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: topView.trailingAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: topView.centerYAnchor)
        ])
        
        stackView.addArrangedSubview(topView)
        
        let getStartedTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(getStartedButtonTapped(_:)))
        // Adjust gesture recognizer settings for smooth interaction
        getStartedTapGestureRecognizer.cancelsTouchesInView = false
        getStartedTapGestureRecognizer.delaysTouchesBegan = false
        getStartedTapGestureRecognizer.delaysTouchesEnded = true
        getStartedButton.addGestureRecognizer(getStartedTapGestureRecognizer)
        
        stackView.addArrangedSubview(getStartedButton)
    }
    
    @objc func getStartedButtonTapped(_ sender: UITapGestureRecognizer) {
        let navigationService = NavigationService()
        navigationService.presentBattle(from: self)
    }
}
