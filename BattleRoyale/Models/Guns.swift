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
    var magazineSize: Int
    var isSemiAuto: Bool
    var damagePerShot: Double
    
    var fileName: String
    
    init(name: String, description: String, image: UIImage, reloadTime: Double, magazineSize: Int, isSemiAuto: Bool, damagePerShot: Double, fileName: String) {
        self.name = name
        self.description = description
        self.image = image
        self.reloadTime = reloadTime
        self.magazineSize = magazineSize
        self.isSemiAuto = isSemiAuto
        self.damagePerShot = damagePerShot
        self.fileName = fileName
    }
}

