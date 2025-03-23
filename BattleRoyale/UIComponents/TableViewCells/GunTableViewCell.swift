//
//  GunTableViewCell.swift
//  BattleRoyale
//
//  Created by Lukas Seklir on 3/22/25.
//

import UIKit

class GunTableViewCell: UITableViewCell {
    
    let containerView = UIView()
    let nameLabel = UILabel.createLabel(fontSize: 18, color: .black, thickness: .bold, numLines: 0, alignment: .left)
    let descriptionLabel = UILabel.createLabel(fontSize: 14, color: .systemGray, thickness: .semibold, numLines: 0, alignment: .left)
    let reloadTimeLabel = UILabel.createLabel(fontSize: 14, color: .systemGray, thickness: .semibold, numLines: 0, alignment: .left)
    let magazineSizeLabel = UILabel.createLabel(fontSize: 14, color: .systemGray, thickness: .semibold, numLines: 0, alignment: .left)
    let isSemiAutoLabel = UILabel.createLabel(fontSize: 14, color: .systemGray, thickness: .semibold, numLines: 0, alignment: .left)
    let damagePerShotLabel = UILabel.createLabel(fontSize: 14, color: .systemGray, thickness: .semibold, numLines: 0, alignment: .left)

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
    }
    
    func updateView() {
        guard let gun = gun else { return }
        
        nameLabel.text = gun.name
        descriptionLabel.text = gun.description
        reloadTimeLabel.text = "Reload Time: \(gun.reloadTime)"
        magazineSizeLabel.text = "Mag Size: \(gun.magazineSize)"
        isSemiAutoLabel.text = gun.isSemiAuto ? "Semi-Auto" : "Full-Auto"
        damagePerShotLabel.text = "Damage: \(gun.damagePerShot)"
    }
}

