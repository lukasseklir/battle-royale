//
//  StandardButton.swift
//  BattleRoyale
//
//  Created by Lukas Seklir on 3/22/25.
//

import UIKit

class StandardButton: UIView {

    private var feedbackGenerator: UIImpactFeedbackGenerator?
    private var isAnimating = false
    private let titleLabel = UILabel.createLabel(fontSize: 16, thickness: .bold)
    private let stackView = UIStackView.createStackView(axis: .horizontal, spacing: 4, alignment: .center, distribution: .fill)
    private let imageView = UIImageView()

    private var heightConstraint: NSLayoutConstraint?

    init(title: String, tintColor: UIColor, backgroundColor: UIColor, height: CGFloat = 60) {
        super.init(frame: .zero)
        setupButton(title: title, tintColor: tintColor, backgroundColor: backgroundColor, height: height)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupButton(title: "Button", tintColor: .blue, backgroundColor: .white, height: 60)
    }

    private func setupButton(title: String, tintColor: UIColor, backgroundColor: UIColor, height: CGFloat) {
        self.translatesAutoresizingMaskIntoConstraints = false
        self.layer.cornerRadius = 20
        self.backgroundColor = backgroundColor

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textColor = tintColor
        titleLabel.text = title

        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = tintColor
        imageView.isHidden = true
        imageView.widthAnchor.constraint(equalToConstant: 20).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: 20).isActive = true

        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(imageView)
        stackView.addArrangedSubview(titleLabel)
        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        ])

        heightConstraint = self.heightAnchor.constraint(equalToConstant: height)
        heightConstraint?.isActive = true

        feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        feedbackGenerator?.prepare()
        self.isUserInteractionEnabled = true
    }

    func setImage(_ image: UIImage?) {
        imageView.image = image
        imageView.isHidden = image == nil
    }

    func hideImage() {
        imageView.isHidden = true
    }

    func updateTintColor(_ color: UIColor) {
        titleLabel.textColor = color
        imageView.tintColor = color
    }

    func updateBackgroundColor(_ color: UIColor) {
        self.backgroundColor = color
    }

    func updateTitle(_ title: String) {
        self.titleLabel.text = title
    }

    func setHeight(_ height: CGFloat) {
        heightConstraint?.constant = height
        layoutIfNeeded()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        animateDown()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        animateUp()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        animateUp()
    }

    private func animateDown(completion: (() -> Void)? = nil) {
        guard !isAnimating else { return }
        isAnimating = true

        feedbackGenerator?.impactOccurred()

        UIView.animate(withDuration: 0.1, delay: 0, options: [.allowUserInteraction, .beginFromCurrentState], animations: {
            self.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            self.isAnimating = false
            completion?()
        }
    }

    private func animateUp() {
        if isAnimating {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.animateUp()
            }
        } else {
            UIView.animate(withDuration: 0.1, delay: 0, options: [.allowUserInteraction, .beginFromCurrentState], animations: {
                self.transform = CGAffineTransform.identity
            }, completion: nil)
        }
    }

    func disable() {
        self.isUserInteractionEnabled = false
        self.alpha = 0.5
    }

    func enable() {
        self.isUserInteractionEnabled = true
        UIView.animate(withDuration: 0.3) {
            self.alpha = 1.0
        }
    }
}

