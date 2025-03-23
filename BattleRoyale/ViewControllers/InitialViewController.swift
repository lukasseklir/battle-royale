//
//  InitialViewController.swift
//  BattleRoyale
//
//  Created by Lukas Seklir on 3/22/25.
//

import UIKit

class InitialViewController: UIViewController {

    let titleLabel = UILabel.createLabel(fontSize: 40, color: .white, thickness: .heavy, numLines: 0, text: "Let's\nBattle")
    let getStartedButton = StandardButton(title: "Get Started", tintColor: .systemIndigo, backgroundColor: .white)
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
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
        getStartedTapGestureRecognizer.cancelsTouchesInView = false
        getStartedTapGestureRecognizer.delaysTouchesBegan = false
        getStartedTapGestureRecognizer.delaysTouchesEnded = true
        getStartedButton.addGestureRecognizer(getStartedTapGestureRecognizer)
        
        stackView.addArrangedSubview(getStartedButton)
    }
    
    @objc func getStartedButtonTapped(_ sender: UITapGestureRecognizer) {
        let navigationService = NavigationService()
        navigationService.presentGunSelector(from: self)
    }
}
