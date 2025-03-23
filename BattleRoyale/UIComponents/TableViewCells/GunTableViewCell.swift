//
//  GunTableViewCell.swift
//  BattleRoyale
//
//  Created by Lukas Seklir on 3/22/25.
//

import UIKit
import SwiftUI
import SceneKit
import RealityKit

class GunTableViewCell: UITableViewCell {
    
    let containerView = UIView()
    let nameLabel = UILabel.createLabel(fontSize: 18, color: .black, thickness: .bold, numLines: 0, alignment: .left)
    let descriptionLabel = UILabel.createLabel(fontSize: 14, color: .systemGray, thickness: .semibold, numLines: 0, alignment: .left)
    let reloadTimeLabel = UILabel.createLabel(fontSize: 14, color: .systemGray, thickness: .semibold, numLines: 0, alignment: .left)
    let magazineSizeLabel = UILabel.createLabel(fontSize: 14, color: .systemGray, thickness: .semibold, numLines: 0, alignment: .left)
    let isSemiAutoLabel = UILabel.createLabel(fontSize: 14, color: .systemGray, thickness: .semibold, numLines: 0, alignment: .left)
    let damagePerShotLabel = UILabel.createLabel(fontSize: 14, color: .systemGray, thickness: .semibold, numLines: 0, alignment: .left)
    let gunModelView = UIView(frame: CGRect(x: 50, y: 100, width: 300, height: 300))

    var gun: Gun? {
        didSet {
            updateView()
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    private func setupViews() {
        self.backgroundColor = .clear
        contentView.backgroundColor = .clear
        contentView.insetSubview(containerView, top: 4, bottom: 20, left: 0, right: 0)
        containerView.roundCornersStandard()
        containerView.backgroundColor = .systemGray6
        
        let gunStackView = UIStackView.createStackView(axis: .horizontal, spacing: 10)
        containerView.insetSubview(gunStackView, top: 16, bottom: 16, left: 16, right: 16)
        
        let gunDescStackView = UIStackView.createStackView(axis: .vertical, spacing: 5)
        gunDescStackView.addArrangedSubview(nameLabel)
        gunDescStackView.addArrangedSubview(descriptionLabel)
        gunDescStackView.addArrangedSubview(reloadTimeLabel)
        gunDescStackView.addArrangedSubview(magazineSizeLabel)
        gunDescStackView.addArrangedSubview(isSemiAutoLabel)
        gunDescStackView.addArrangedSubview(damagePerShotLabel)
        
        gunStackView.addArrangedSubview(gunDescStackView)
        gunStackView.addArrangedSubview(gunModelView)
    }
    
    func updateView() {
        guard let gun = gun else { return }
        
        nameLabel.text = gun.name
        descriptionLabel.text = gun.description
        reloadTimeLabel.text = "Reload Time: \(gun.reloadTime)"
        magazineSizeLabel.text = "Mag Size: \(gun.magazineSize)"
        isSemiAutoLabel.text = gun.isSemiAuto ? "Semi-Auto" : "Full-Auto"
        damagePerShotLabel.text = "Damage: \(gun.damagePerShot)"
        
        gunModelView.subviews.forEach { $0.removeFromSuperview() }
        
        // Create a SceneView to display the 3D model
        let sceneView = SCNView()
        sceneView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add sceneView to gunModelView and set constraints
        gunModelView.addSubview(sceneView)
        NSLayoutConstraint.activate([
            sceneView.topAnchor.constraint(equalTo: gunModelView.topAnchor),
            sceneView.bottomAnchor.constraint(equalTo: gunModelView.bottomAnchor),
            sceneView.leadingAnchor.constraint(equalTo: gunModelView.leadingAnchor),
            sceneView.trailingAnchor.constraint(equalTo: gunModelView.trailingAnchor)
        ])
        
        // Set width constraint if needed
        gunModelView.widthAnchor.constraint(equalToConstant: 300).isActive = true

        
        // Adjust gesture recognizers to cancel touches propagation
        if let gestures = sceneView.gestureRecognizers {
            for gesture in gestures {
                gesture.cancelsTouchesInView = true
            }
        }
        
        // Load the model scene
        if let modelScene = SCNScene(named: gun.fileName) {
            // Add lighting to the scene
            let lightNode = SCNNode()
            lightNode.light = SCNLight()
            lightNode.light?.type = .omni
            lightNode.position = SCNVector3(x: 0, y: 10, z: 35)
            modelScene.rootNode.addChildNode(lightNode)

            // Add a rotation action to the model node
            if let modelNode = modelScene.rootNode.childNodes.first {
                let rotateAction = SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: 5))
                modelNode.runAction(rotateAction)
            }

            // Set scene to sceneView
            sceneView.autoenablesDefaultLighting = true
            sceneView.allowsCameraControl = true
            sceneView.backgroundColor = .clear
            sceneView.scene = modelScene
        } else {
            print("Failed to load the scene: \(gun.fileName)")
        }
    }
}

