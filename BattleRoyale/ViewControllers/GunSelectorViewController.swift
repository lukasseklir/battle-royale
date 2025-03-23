//
//  GunSelectorViewController.swift
//  BattleRoyale
//
//  Created by Lukas Seklir on 3/22/25.
//

import UIKit
import SwiftUI
import RealityKit

protocol GunSelectorDelegate: AnyObject {
    func didSelectGun(_ gun: Gun)
}

class GunSelectorViewController: UIViewController {
    
    let gunsTableView = GunsTableView()
    weak var delegate: GunSelectorDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    func setupUI() {
        self.view.backgroundColor = .white
        
        view.addSubview(gunsTableView)
        gunsTableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            gunsTableView.topAnchor.constraint(equalTo: view.topAnchor, constant: 10),
            gunsTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            gunsTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            gunsTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -10)
        ])
        
        let gunsService = GunService.shared
        gunsTableView.guns = gunsService.guns
        gunsTableView.gunSelectionDelegate = self
        
        let dismissButton = UIButton(type: .system)
        dismissButton.setTitle("X", for: .normal)
        dismissButton.tintColor = .black
        dismissButton.titleLabel?.font = .boldSystemFont(ofSize: 24)
        dismissButton.addTarget(self, action: #selector(dismissSelf), for: .touchUpInside)
        view.addSubview(dismissButton)
        dismissButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            dismissButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            dismissButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16)
        ])
    }
    
    @objc func dismissSelf() {
        dismiss(animated: true, completion: nil)
    }
}

extension GunSelectorViewController: GunsTableViewDelegate {
    func didSelectGun(_ gun: Gun) {
        let battleVC = BattleViewController()
        battleVC.selectedGun = gun
        battleVC.modalPresentationStyle = .fullScreen
        self.present(battleVC, animated: true, completion: nil)
    }
}
