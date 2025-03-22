//
//  BattleViewController.swift
//  BattleRoyale
//
//  Created by Lukas Seklir on 3/22/25.
//

import UIKit
import AVFoundation
import Vision

class BattleViewController: UIViewController, UIGestureRecognizerDelegate {
    
    let bulletCountContainerView = UIView()
    let bulletCountLabel = UILabel.createLabel(fontSize: 18, color: .white, thickness: .bold, alignment: .center)
    
    let gunSelectorContainerView = UIView()
    let gunSelectorLabel = UILabel.createLabel(fontSize: 18, color: .white, thickness: .bold, alignment: .center)
    
    var selectedGun: Gun?
    
    var nightVisionEnabled: Bool = false
    var nightVisionImageView: UIImageView!
    let ciContext = CIContext()
    
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    
    // Bullet count based on selected gun's magazine size.
    var bulletCount: Int = 0
    var initialBulletCount: Int {
        return selectedGun?.magazineSize ?? 10
    }
    var isReloading: Bool = false
    var crosshairView: UIView!
    
    var latestObservations: [VNDetectedObjectObservation] = []
    
    // Timer for full auto firing.
    var autoFireTimer: Timer?
    
    // Property for nightVisionSwitch (changed from local variable).
    var nightVisionSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCamera()
        
        nightVisionImageView = UIImageView(frame: view.bounds)
        nightVisionImageView.contentMode = .scaleAspectFill
        nightVisionImageView.isHidden = true
        view.addSubview(nightVisionImageView)
        
        setupCrosshair()
        setupBulletCountLabel()
        setupNightVisionToggle()
        setupGunSelectorLabel()
        
        // Set a random gun on first launch.
        if let randomGun = GunService.shared.guns.randomElement() {
            selectedGun = randomGun
            gunSelectorLabel.text = randomGun.name
            bulletCount = randomGun.magazineSize  // Initialize bullet count based on gun's magazine size.
            updateBulletCountLabel("\(bulletCount)")
        }
        
        // Replace tap gesture with a long press gesture to handle semi and full auto fire.
        let fireGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleFireGesture(_:)))
        fireGesture.minimumPressDuration = 0 // Fires immediately.
        // Set delegate so touches on controls are ignored.
        fireGesture.delegate = self
        view.addGestureRecognizer(fireGesture)
    }
    
    // MARK: - UIGestureRecognizerDelegate
    
    // Prevent fireGesture from receiving touches on gunSelectorContainerView and nightVisionSwitch.
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if let touchedView = touch.view {
            if touchedView.isDescendant(of: gunSelectorContainerView) ||
               touchedView.isDescendant(of: nightVisionSwitch) {
                return false
            }
        }
        return true
    }
    
    // MARK: - Setup Methods
    
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

        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
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
        bulletCountContainerView.translatesAutoresizingMaskIntoConstraints = false
        bulletCountLabel.translatesAutoresizingMaskIntoConstraints = false

        bulletCountContainerView.backgroundColor = .black.withAlphaComponent(0.5)
        bulletCountContainerView.layer.cornerRadius = 10
        bulletCountContainerView.clipsToBounds = true

        bulletCountContainerView.addSubview(bulletCountLabel)
        view.addSubview(bulletCountContainerView)

        updateBulletCountLabel("\(bulletCount)")

        NSLayoutConstraint.activate([
            bulletCountContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            bulletCountContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            bulletCountLabel.topAnchor.constraint(equalTo: bulletCountContainerView.topAnchor, constant: 5),
            bulletCountLabel.bottomAnchor.constraint(equalTo: bulletCountContainerView.bottomAnchor, constant: -5),
            bulletCountLabel.leadingAnchor.constraint(equalTo: bulletCountContainerView.leadingAnchor, constant: 5),
            bulletCountLabel.trailingAnchor.constraint(equalTo: bulletCountContainerView.trailingAnchor, constant: -5)
        ])
    }
    
    func setupGunSelectorLabel() {
        gunSelectorContainerView.translatesAutoresizingMaskIntoConstraints = false
        gunSelectorLabel.translatesAutoresizingMaskIntoConstraints = false

        gunSelectorContainerView.backgroundColor = .black.withAlphaComponent(0.5)
        gunSelectorContainerView.layer.cornerRadius = 10
        gunSelectorContainerView.clipsToBounds = true

        gunSelectorContainerView.addSubview(gunSelectorLabel)
        view.addSubview(gunSelectorContainerView)

        NSLayoutConstraint.activate([
            gunSelectorContainerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            gunSelectorContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            gunSelectorLabel.topAnchor.constraint(equalTo: gunSelectorContainerView.topAnchor, constant: 5),
            gunSelectorLabel.bottomAnchor.constraint(equalTo: gunSelectorContainerView.bottomAnchor, constant: -5),
            gunSelectorLabel.leadingAnchor.constraint(equalTo: gunSelectorContainerView.leadingAnchor, constant: 5),
            gunSelectorLabel.trailingAnchor.constraint(equalTo: gunSelectorContainerView.trailingAnchor, constant: -5)
        ])
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(gunSelectorTapped))
        gunSelectorContainerView.addGestureRecognizer(tapGesture)
        gunSelectorContainerView.isUserInteractionEnabled = true
    }
    
    @objc func gunSelectorTapped() {
        print("gun selector tapped")
        let gunSelectorVC = GunSelectorViewController()
        gunSelectorVC.delegate = self
        present(gunSelectorVC, animated: true, completion: nil)
    }
    
    func updateBulletCountLabel(_ text: String) {
        bulletCountLabel.text = "Ammo: \(text)"
    }
    
    func setupNightVisionToggle() {
        // Use the property nightVisionSwitch to allow gesture filtering.
        nightVisionSwitch = UISwitch()
        nightVisionSwitch.translatesAutoresizingMaskIntoConstraints = false
        nightVisionSwitch.addTarget(self, action: #selector(nightVisionSwitchChanged(_:)), for: .valueChanged)
        view.addSubview(nightVisionSwitch)
        
        let nightVisionLabel = UILabel()
        nightVisionLabel.text = "Night Vision"
        nightVisionLabel.textColor = .white
        nightVisionLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(nightVisionLabel)
        
        NSLayoutConstraint.activate([
            nightVisionSwitch.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            nightVisionSwitch.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            nightVisionLabel.centerYAnchor.constraint(equalTo: nightVisionSwitch.centerYAnchor),
            nightVisionLabel.leadingAnchor.constraint(equalTo: nightVisionSwitch.trailingAnchor, constant: 8)
        ])
    }
    
    @objc func nightVisionSwitchChanged(_ sender: UISwitch) {
        nightVisionEnabled = sender.isOn
        nightVisionImageView.isHidden = !nightVisionEnabled
    }
    
    // Gesture handler to differentiate between semi and full auto firing modes.
    @objc func handleFireGesture(_ gesture: UILongPressGestureRecognizer) {
        guard let gun = selectedGun else { return }
        if gun.isSemiAuto {
            // Semi-auto: fire once when gesture begins.
            if gesture.state == .began {
                shoot()
            }
        } else {
            // Full-auto: start firing continuously while pressed.
            if gesture.state == .began {
                autoFireTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                    self?.shoot()
                }
            } else if gesture.state == .ended || gesture.state == .cancelled {
                autoFireTimer?.invalidate()
                autoFireTimer = nil
            }
        }
    }
    
    func shoot() {
        if isReloading { return }
        if bulletCount > 0 {
            bulletCount -= 1
            updateBulletCountLabel("\(bulletCount)")
            
            let shootHaptic = UIImpactFeedbackGenerator(style: .medium)
            shootHaptic.impactOccurred()
            
            if isPersonInCrosshair() {
                let hitHaptic = UINotificationFeedbackGenerator()
                hitHaptic.notificationOccurred(.success)
                animateHitFeedback()
            }
        } else {
            isReloading = true
            updateBulletCountLabel("Reloading...")
            if let reloadTime = selectedGun?.reloadTime {
                DispatchQueue.main.asyncAfter(deadline: .now() + reloadTime) { [weak self] in
                    guard let self = self else { return }
                    self.bulletCount = self.initialBulletCount
                    self.isReloading = false
                    self.updateBulletCountLabel("\(self.bulletCount)")
                }
            }
        }
    }
    
    func animateHitFeedback() {
        for subview in crosshairView.subviews {
            let originalColor = subview.backgroundColor
            UIView.animate(withDuration: 0.1, animations: {
                subview.backgroundColor = UIColor.green
            }) { _ in
                UIView.animate(withDuration: 0.1) {
                    subview.backgroundColor = originalColor
                }
            }
        }
    }
}

extension BattleViewController {
    func viewRect(for observation: VNDetectedObjectObservation) -> CGRect {
        let normalizedRect = observation.boundingBox
        let metadataRect = CGRect(
            x: normalizedRect.origin.x,
            y: 1 - normalizedRect.origin.y - normalizedRect.height,
            width: normalizedRect.width,
            height: normalizedRect.height
        )
        return previewLayer.layerRectConverted(fromMetadataOutputRect: metadataRect)
    }
    
    func isPersonInCrosshair() -> Bool {
        for observation in latestObservations {
            let detectionRect = viewRect(for: observation)
            if crosshairView.frame.intersects(detectionRect) {
                return true
            }
        }
        return false
    }
}

extension BattleViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let request = VNDetectHumanRectanglesRequest { [weak self] request, error in
            guard let self = self,
                  let observations = request.results as? [VNDetectedObjectObservation] else { return }
            DispatchQueue.main.async {
                self.latestObservations = observations
            }
        }
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        do {
            try handler.perform([request])
        } catch {
            print("Vision request failed: \(error)")
        }
        
        if nightVisionEnabled {
            let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            if let filter = CIFilter(name: "CIColorMonochrome") {
                filter.setValue(ciImage, forKey: kCIInputImageKey)
                filter.setValue(CIColor(red: 0.0, green: 1.0, blue: 0.0), forKey: kCIInputColorKey)
                filter.setValue(1.0, forKey: kCIInputIntensityKey)
                if let outputImage = filter.outputImage,
                   let cgImage = ciContext.createCGImage(outputImage, from: outputImage.extent) {
                    let uiImage = UIImage(cgImage: cgImage)
                    DispatchQueue.main.async {
                        self.nightVisionImageView.image = uiImage
                    }
                }
            }
        }
    }
}

extension BattleViewController: GunSelectorDelegate {
    // When a new gun is selected, start in reloading mode and update the bullet count based on the gun.
    func didSelectGun(_ gun: Gun) {
        selectedGun = gun
        gunSelectorLabel.text = gun.name
        
        isReloading = true
        updateBulletCountLabel("Reloading...")
        DispatchQueue.main.asyncAfter(deadline: .now() + gun.reloadTime) { [weak self] in
            guard let self = self else { return }
            self.bulletCount = gun.magazineSize
            self.isReloading = false
            self.updateBulletCountLabel("\(self.bulletCount)")
        }
    }
}
