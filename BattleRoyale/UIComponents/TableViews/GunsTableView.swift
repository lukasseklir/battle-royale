//
//  GunSelectorTableView.swift
//  BattleRoyale
//
//  Created by Lukas Seklir on 3/22/25.
//

import UIKit

protocol GunsTableViewDelegate: AnyObject {
    func didSelectGun(_ gun: Gun)
}

class GunsTableView: UITableView {
    
    weak var gunSelectionDelegate: GunsTableViewDelegate?
    var guns: [Gun] = [] {
        didSet {
            reloadData()
        }
    }

    override init(frame: CGRect, style: UITableView.Style) {
        super.init(frame: frame, style: style)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        backgroundColor = .clear
        rowHeight = UITableView.automaticDimension
        estimatedRowHeight = 100
        separatorStyle = .none
        isScrollEnabled = true
        showsVerticalScrollIndicator = false
        register(GunTableViewCell.self, forCellReuseIdentifier: "GunCell")
        dataSource = self
        delegate = self
    }
}

extension GunsTableView: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guns.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GunCell", for: indexPath) as! GunTableViewCell
        cell.gun = guns[indexPath.item]
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedGun = guns[indexPath.row]
        gunSelectionDelegate?.didSelectGun(selectedGun)
    }
}
