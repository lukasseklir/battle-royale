//
//  GunsService.swift
//  BattleRoyale
//
//  Created by Lukas Seklir on 3/22/25.
//

import UIKit

class GunService {
    
    static let shared = GunService()
    
    let guns = [
        Gun(
            name: "Banana Blaster",
            description: "A powerful semi-automatic fruit launcher that fires pressurized banana peels. Victims slip guaranteed!",
            image: UIImage(named: "bananaBlaster") ?? UIImage(),
            reloadTime: 2.5,
            magazineSize: 7,
            isSemiAuto: true,
            damagePerShot: 45.0,
            fileName: "Banana_Gun.usdz"
        ),
        
        Gun(
            name: "Frost Blaster",
            description: "A chilling weapon that freezes enemies in their tracks. Cold, but effective.",
            image: UIImage(named: "iceGun") ?? UIImage(),
            reloadTime: 3.0,
            magazineSize: 6,
            isSemiAuto: true,
            damagePerShot: 65.0,
            fileName: "Ice_Gun.usdz"
        ),
        
        Gun(
            name: "Rubber Band Sniper",
            description: "High-precision office supply launcher. Extremely painful finger flick but requires perfect aim.",
            image: UIImage(named: "rubberBandSniper") ?? UIImage(),
            reloadTime: 4.0,
            magazineSize: 5,
            isSemiAuto: true,
            damagePerShot: 95.0,
            fileName: "Rubber_Band.usdz"
        ),
        
        Gun(
            name: "Bubble Blaster",
            description: "Rapid-fire soap bubble generator with blinding foam setting. Leaves enemies squeaky clean but disoriented.",
            image: UIImage(named: "bubbleBlaster") ?? UIImage(),
            reloadTime: 1.8,
            magazineSize: 25,
            isSemiAuto: false,
            damagePerShot: 18.0,
            fileName: "Bubble_Gun.usdz"
        ),
        
        Gun(
            name: "Water Blaster",
            description: "A high-pressure water gun that soaks enemies in an instant. Perfect for summer battles and unexpected drenchings.",
            image: UIImage(named: "waterBlaster") ?? UIImage(),
            reloadTime: 2.5,
            magazineSize: 10,
            isSemiAuto: false,
            damagePerShot: 30.0,
            fileName: "Water_Gun.usdz"
        ),
        
        Gun(
            name: "Ray Gun",
            description: "A futuristic energy weapon that disintegrates targets with concentrated plasma beams.",
            image: UIImage(named: "rayGun") ?? UIImage(),
            reloadTime: 2.5,
            magazineSize: 20,
            isSemiAuto: true,
            damagePerShot: 50.0,
            fileName: "RAY_GUN.usdz"
        )


    ]
}
