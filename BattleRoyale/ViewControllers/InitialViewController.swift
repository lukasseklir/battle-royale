//
//  InitialViewController.swift
//  BattleRoyale
//
//  Created by Lukas Seklir on 3/22/25.
//

import UIKit

class InitialViewController: UIViewController {

    let titleLabel = UILabel.createLabel(fontSize: 40, color: .white, thickness: .heavy, numLines: 0, text: "Battle Royale")
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
    }
    
    func setupUI() {
        self.view.backgroundColor = .white
        
        let backgroundImageView = UIImageView()
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(backgroundImageView)
        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: self.view.topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])
        backgroundImageView.image = UIImage(named: "camo")
        
        let stackView = UIStackView.createStackView(axis: .vertical, spacing: 20, alignment: .center)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 32),
            stackView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -32),
            stackView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor)
        ])
        
        let backgroundColor = UIColor(
            red: CGFloat(0xF1) / 255.0,  // 241
            green: CGFloat(0xC9) / 255.0,  // 201
            blue: CGFloat(0x95) / 255.0,  // 149
            alpha: 1.0
        )
        
        let textColor = UIColor(
            red: CGFloat(0x22) / 255.0,  // 34
            green: CGFloat(0x28) / 255.0,  // 40
            blue: CGFloat(0x24) / 255.0,  // 36
            alpha: 1.0
        )
        
        let getStartedButton = StandardButton(title: "Let's Battle", tintColor: textColor, backgroundColor: backgroundColor)
        getStartedButton.widthAnchor.constraint(equalToConstant: 300).isActive = true
        
        let getStartedTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(getStartedButtonTapped(_:)))
        getStartedTapGestureRecognizer.cancelsTouchesInView = false
        getStartedTapGestureRecognizer.delaysTouchesBegan = false
        getStartedTapGestureRecognizer.delaysTouchesEnded = true
        getStartedButton.addGestureRecognizer(getStartedTapGestureRecognizer)
        
        titleLabel.textAlignment = .center
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(getStartedButton)
    }
    
    @objc func getStartedButtonTapped(_ sender: UITapGestureRecognizer) {
        let navigationService = NavigationService()
        navigationService.presentGunSelector(from: self)
    }
}
