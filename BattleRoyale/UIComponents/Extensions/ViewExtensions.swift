//
//  ViewExtensions.swift
//  BattleRoyale
//
//  Created by Lukas Seklir on 3/22/25.
//

import UIKit

extension UIView {
    
    func insetSubview(_ subview: UIView, top: CGFloat, bottom: CGFloat, left: CGFloat, right: CGFloat) {
        addSubview(subview)
        subview.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            subview.topAnchor.constraint(equalTo: self.topAnchor, constant: top),
            subview.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -bottom),
            subview.leftAnchor.constraint(equalTo: self.leftAnchor, constant: left),
            subview.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -right)
        ])
    }
    
    func centerSubviewHorizontally(_ subview: UIView, top: CGFloat, bottom: CGFloat) {
        addSubview(subview)
        subview.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            subview.topAnchor.constraint(equalTo: self.topAnchor, constant: top),
            subview.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -bottom),
            subview.centerXAnchor.constraint(equalTo: self.centerXAnchor)
        ])
    }
    
    func insetSubviewByZero(_ subview: UIView) {
        insetSubview(subview, top: 0, bottom: 0, left: 0, right: 0)
    }
    
    func insetSubviewHorizontally(_ subview: UIView, inset: CGFloat) {
        insetSubview(subview, top: 0, bottom: 0, left: inset, right: inset)
    }
    
    func addOuterShadow(radius: CGFloat = 10, color: UIColor = .black, opacity: Float = 0.5, offset: CGSize = .zero) {
        layer.shadowColor = color.cgColor
        layer.shadowOpacity = opacity
        layer.shadowOffset = offset
        layer.shadowRadius = radius
        layer.masksToBounds = false
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: layer.cornerRadius).cgPath
    }
    
    func roundCornersStandard() {
        roundCorners(amount: 20)
    }
    
    func roundCorners(amount: CGFloat) {
        self.layer.cornerRadius = amount
        self.clipsToBounds = true
    }
    
    func addDropShadow(color: UIColor = .black, opacity: Float = 0.5, offset: CGSize = CGSize(width: 0, height: 4), radius: CGFloat = 5) {
        layer.shadowColor = color.cgColor
        layer.shadowOpacity = opacity
        layer.shadowOffset = offset
        layer.shadowRadius = radius
        clipsToBounds = false
        layer.masksToBounds = false
    }
    
    func setupPillView() {
        let pillView = UIView()
        pillView.backgroundColor = .systemGray5
        pillView.layer.cornerRadius = 3

        addSubview(pillView)

        pillView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pillView.topAnchor.constraint(equalTo: topAnchor, constant: 5),
            pillView.centerXAnchor.constraint(equalTo: centerXAnchor),
            pillView.widthAnchor.constraint(equalToConstant: 100),
            pillView.heightAnchor.constraint(equalToConstant: 5)
        ])
    }
}
