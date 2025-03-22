//
//  StackViewExtensions.swift
//  BattleRoyale
//
//  Created by Lukas Seklir on 3/22/25.
//

import UIKit

extension UIStackView {
    
    static func createStackView(axis: NSLayoutConstraint.Axis, spacing: CGFloat? = nil, alignment: UIStackView.Alignment? = nil, distribution: UIStackView.Distribution? = nil) -> UIStackView {
        let stackView = UIStackView()
        stackView.axis = axis
        
        if let spacing = spacing {
            stackView.spacing = spacing
        }
        
        if let alignment = alignment {
            stackView.alignment = alignment
        }
        
        if let distribution = distribution {
            stackView.distribution = distribution
        }
        
        return stackView
    }
}
