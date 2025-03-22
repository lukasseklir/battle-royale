//
//  GunsService.swift
//  BattleRoyale
//
//  Created by Lukas Seklir on 3/22/25.
//

import UIKit

class GunsService {
    
    static let shared = GunsService()
    
    let guns = [
        Gun(
            name: "Banana Blaster",
            description: "A powerful semi-automatic fruit launcher that fires pressurized banana peels. Victims slip guaranteed!",
            image: UIImage(named: "bananaBlaster") ?? UIImage(),
            reloadTime: 2.5,
            magazineSize: 7,
            isSemiAuto: true,
            damagePerShot: 45.0
        ),
        
        Gun(
            name: "Sock Launcher 3000",
            description: "Rapid-fires rolled-up socks with pinpoint accuracy. Comes pre-loaded with mismatched pairs for extra confusion.",
            image: UIImage(named: "sockLauncher") ?? UIImage(),
            reloadTime: 3.0,
            magazineSize: 30,
            isSemiAuto: false,
            damagePerShot: 32.0
        ),
        
        Gun(
            name: "Glitter Cannon",
            description: "Close-range weapon with devastating spread of craft supplies. Victims will be finding glitter for YEARS.",
            image: UIImage(named: "glitterCannon") ?? UIImage(),
            reloadTime: 4.5,
            magazineSize: 8,
            isSemiAuto: false,
            damagePerShot: 75.0
        ),
        
        Gun(
            name: "Rubber Band Sniper",
            description: "High-precision office supply launcher. Extremely painful finger flick but requires perfect aim.",
            image: UIImage(named: "rubberBandSniper") ?? UIImage(),
            reloadTime: 4.0,
            magazineSize: 5,
            isSemiAuto: true,
            damagePerShot: 95.0
        ),
        
        Gun(
            name: "Bubble Blaster",
            description: "Rapid-fire soap bubble generator with blinding foam setting. Leaves enemies squeaky clean but disoriented.",
            image: UIImage(named: "bubbleBlaster") ?? UIImage(),
            reloadTime: 1.8,
            magazineSize: 25,
            isSemiAuto: false,
            damagePerShot: 18.0
        ),
        
        Gun(
            name: "T-Shirt Cannon",
            description: "Fires rolled-up promotional t-shirts at unsuspecting targets. Free merch is surprisingly effective in battle.",
            image: UIImage(named: "tshirtCannon") ?? UIImage(),
            reloadTime: 3.2,
            magazineSize: 6,
            isSemiAuto: true,
            damagePerShot: 60.0
        )
    ]
}
