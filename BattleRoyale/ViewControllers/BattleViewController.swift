//
//  BattleViewController.swift
//  BattleRoyale
//
//  Created by Lukas Seklir on 3/22/25.
//

import UIKit
import AVFoundation

class BattleViewController: UIViewController {
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    
    var bulletCount: Int = 10
    let initialBulletCount: Int = 10
    var isReloading: Bool = false
    var bulletCountLabel: UILabel!
    var crosshairView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
        setupOverlay()
        setupCrosshair()
        setupBulletCountLabel()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        view.addGestureRecognizer(tapGesture)
    }
    
    func setupCamera() {
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .high
        
        guard let camera = AVCaptureDevice.default(for: .video) else {
            print("No camera available")
            return
        }
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }
        } catch {
            print("Error setting device input: \(error)")
            return
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        if let connection = previewLayer.connection, connection.isVideoOrientationSupported {
            connection.videoOrientation = .landscapeRight
        }
        view.layer.insertSublayer(previewLayer, at: 0)
        captureSession.startRunning()
    }
    
    func setupOverlay() {
        let overlayLabel = UILabel()
        overlayLabel.text = "Camera Overlay"
        overlayLabel.textColor = .white
        overlayLabel.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        overlayLabel.textAlignment = .center
        overlayLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(overlayLabel)
        NSLayoutConstraint.activate([
            overlayLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            overlayLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            overlayLabel.widthAnchor.constraint(equalToConstant: 200),
            overlayLabel.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    func setupCrosshair() {
        crosshairView = UIView()
        crosshairView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(crosshairView)
        let horizontalLine = UIView()
        horizontalLine.backgroundColor = .red
        horizontalLine.translatesAutoresizingMaskIntoConstraints = false
        crosshairView.addSubview(horizontalLine)
        let verticalLine = UIView()
        verticalLine.backgroundColor = .red
        verticalLine.translatesAutoresizingMaskIntoConstraints = false
        crosshairView.addSubview(verticalLine)
        NSLayoutConstraint.activate([
            crosshairView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            crosshairView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            crosshairView.widthAnchor.constraint(equalToConstant: 40),
            crosshairView.heightAnchor.constraint(equalToConstant: 40),
            horizontalLine.centerYAnchor.constraint(equalTo: crosshairView.centerYAnchor),
            horizontalLine.leadingAnchor.constraint(equalTo: crosshairView.leadingAnchor),
            horizontalLine.trailingAnchor.constraint(equalTo: crosshairView.trailingAnchor),
            horizontalLine.heightAnchor.constraint(equalToConstant: 1),
            verticalLine.centerXAnchor.constraint(equalTo: crosshairView.centerXAnchor),
            verticalLine.topAnchor.constraint(equalTo: crosshairView.topAnchor),
            verticalLine.bottomAnchor.constraint(equalTo: crosshairView.bottomAnchor),
            verticalLine.widthAnchor.constraint(equalToConstant: 1)
        ])
    }
    
    func setupBulletCountLabel() {
        bulletCountLabel = UILabel()
        bulletCountLabel.translatesAutoresizingMaskIntoConstraints = false
        bulletCountLabel.textColor = .white
        bulletCountLabel.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        bulletCountLabel.textAlignment = .center
        bulletCountLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        updateBulletCountLabel()
        view.addSubview(bulletCountLabel)
        NSLayoutConstraint.activate([
            bulletCountLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            bulletCountLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            bulletCountLabel.widthAnchor.constraint(equalToConstant: 50),
            bulletCountLabel.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    func updateBulletCountLabel() {
        bulletCountLabel.text = "\(bulletCount)"
    }
    
    @objc func handleTap() {
        shoot()
    }
    
    func shoot() {
        if isReloading { return }
        if bulletCount > 0 {
            bulletCount -= 1
            updateBulletCountLabel()
            print("Shoot! Bullets left: \(bulletCount)")
        } else {
            isReloading = true
            print("Reloading...")
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
                guard let self = self else { return }
                self.bulletCount = self.initialBulletCount
                self.updateBulletCountLabel()
                self.isReloading = false
                print("Reload complete.")
            }
        }
    }
}
