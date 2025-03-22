//
//  LabelExtensions.swift
//  BattleRoyale
//
//  Created by Lukas Seklir on 3/22/25.
//

import UIKit

extension UILabel {
    static func createLabel(fontSize: CGFloat? = nil, color: UIColor? = nil, thickness: UIFont.Weight? = nil, numLines: Int? = nil, text: String? = nil, alignment: NSTextAlignment? = nil) -> UILabel {
        let label = UILabel()
        
        let size = fontSize ?? UIFont.systemFontSize
        let fontWeight = thickness ?? UIFont.Weight.regular
        
        label.font = UIFont.systemFont(ofSize: size, weight: fontWeight)
        label.textColor = color ?? UIColor.label
        
        if let numLines = numLines {
            label.numberOfLines = numLines
        }
        
        if let text = text {
            label.text = text
        }
        
        if let alignment = alignment {
            label.textAlignment = alignment
        }
        
        return label
    }
}

