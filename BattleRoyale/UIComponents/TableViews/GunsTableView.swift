//
//  GunSelectorTableView.swift
//  BattleRoyale
//
//  Created by Lukas Seklir on 3/22/25.
//

import UIKit

class GunSelectorTableView: UITableView {
    
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
        register(ParagraphTableViewCell.self, forCellReuseIdentifier: "ParagraphCell")
        dataSource = self
        delegate = self
    }
    
    func animateVisibleCells() {
        let visibleCells = self.visibleCells
        
        for cell in visibleCells {
            cell.alpha = 0
        }

        let animations: [() -> Void] = visibleCells.map { cell in
            return {
                cell.alpha = 1
            }
        }

        AnimationService().animateSequentially(
            animations: animations,
            duration: 1.0,
            delayBetween: 0.2
        ) {}
    }

}

extension ParagraphsTableView: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        paragraphs.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ParagraphCell", for: indexPath) as! ParagraphTableViewCell
        cell.paragraph = paragraphs[indexPath.item]
        return cell
    }
}


