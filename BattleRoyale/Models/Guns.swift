//
//  Guns.swift
//  BattleRoyale
//
//  Created by Lukas Seklir on 3/22/25.
//

import UIKit

class Gun {
    var name: String
    var description: String
    var image: UIImage
    
    var reloadTime: Double
    var ammoCount: Int
    var magazineSize: Int
    var isSemiAuto: Bool
    var damagePerShot: Double
    
    init(name: String, description: String, image: UIImage, reloadTime: Double, magazineSize: Int, isSemiAuto: Bool, damagePerShot: Double) {
        self.name = name
        self.description = description
        self.image = image
        self.reloadTime = reloadTime
        self.magazineSize = magazineSize
        self.ammoCount = magazineSize
        self.isSemiAuto = isSemiAuto
        self.damagePerShot = damagePerShot
    }
}

