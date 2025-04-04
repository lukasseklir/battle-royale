//
//  NavigationService.swift
//  BattleRoyale
//
//  Created by Lukas Seklir on 3/22/25.
//

import UIKit

class NavigationService {
    
    func presentBattle(from viewController: UIViewController) {
        let battleVC = BattleViewController()
        battleVC.modalPresentationStyle = .fullScreen
        viewController.present(battleVC, animated: true, completion: nil)
    }
    
    func presentGunSelector(from viewController: UIViewController) {
        let gunSelectorVC = GunSelectorViewController()
        gunSelectorVC.modalPresentationStyle = .fullScreen
        viewController.present(gunSelectorVC, animated: true, completion: nil)
    }
}

