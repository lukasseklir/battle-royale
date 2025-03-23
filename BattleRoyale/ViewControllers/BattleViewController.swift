//
//  BattleViewController.swift
//  BattleRoyale
//
//  Created by Lukas Seklir on 3/22/25.
//

import UIKit
import AVFoundation
import Vision
import Network
import MultipeerConnectivity

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
    
    // Property for nightVisionSwitch.
    var nightVisionSwitch: UISwitch!
    
    var hitmarkerPlayer: AVAudioPlayer?
    var missPlayer: AVAudioPlayer?         // Added for miss sound
    var damagePlayer: AVAudioPlayer?       // Added for damage sound
    
    var udp: UDPCommunication?
    
    // Player's health and health bar.
    var hp: Double = 1000  // Player starts with 1000 hp.
    var healthBarContainer: UIView!
    var healthBarView: UIView!
    var healthBarWidthConstraint: NSLayoutConstraint!
    
    private var multipeerService: MultipeerService!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        multipeerService = MultipeerService()
        multipeerService.delegate = self
        
        // Set up audio session for playback.
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio session setup error: \(error)")
        }
        
        if let hitmarkerUrl = Bundle.main.url(forResource: "hitmarker", withExtension: "mp3") {
            do {
                hitmarkerPlayer = try AVAudioPlayer(contentsOf: hitmarkerUrl)
                hitmarkerPlayer?.prepareToPlay()
            } catch {
                print("Error loading hitmarker sound: \(error)")
            }
        }
        
        // Load miss sound
        if let missUrl = Bundle.main.url(forResource: "miss", withExtension: "mp3") {
            do {
                missPlayer = try AVAudioPlayer(contentsOf: missUrl)
                missPlayer?.prepareToPlay()
            } catch {
                print("Error loading miss sound: \(error)")
            }
        }

        // Load damage sound
        if let damageUrl = Bundle.main.url(forResource: "damage", withExtension: "mp3") {
            do {
                damagePlayer = try AVAudioPlayer(contentsOf: damageUrl)
                damagePlayer?.prepareToPlay()
            } catch {
                print("Error loading damage sound: \(error)")
            }
        }
        
        setupCamera()
        
        nightVisionImageView = UIImageView(frame: view.bounds)
        nightVisionImageView.contentMode = .scaleAspectFill
        nightVisionImageView.isHidden = true
        view.addSubview(nightVisionImageView)
        
        setupCrosshair()
        setupBulletCountLabel()
        setupNightVisionToggle()
        setupGunSelectorLabel()
        setupHealthBar()  // Setup the health bar.
        
        // Set a random gun on first launch.
        if let randomGun = GunService.shared.guns.randomElement() {
            selectedGun = randomGun
            gunSelectorLabel.text = "\(randomGun.name), \(randomGun.isSemiAuto ? "Semi-Auto" : "Full-Auto")"
            bulletCount = randomGun.magazineSize  // Initialize bullet count.
            updateBulletCountLabel("\(bulletCount)")
        }
        
        // Replace tap gesture with long press to handle firing modes.
        let fireGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleFireGesture(_:)))
        fireGesture.minimumPressDuration = 0 // Fires immediately.
        fireGesture.delegate = self  // Prevent touches on controls.
        view.addGestureRecognizer(fireGesture)
    }
    
    // MARK: - UIGestureRecognizerDelegate
    
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
    
    func setupNightVisionToggle() {
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
    
    func setupHealthBar() {
        // Create container for the health bar.
        healthBarContainer = UIView()
        healthBarContainer.translatesAutoresizingMaskIntoConstraints = false
        healthBarContainer.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        healthBarContainer.layer.cornerRadius = 5
        view.addSubview(healthBarContainer)
        
        // Create the red health bar view.
        healthBarView = UIView()
        healthBarView.translatesAutoresizingMaskIntoConstraints = false
        healthBarView.backgroundColor = .red
        healthBarView.layer.cornerRadius = 5
        healthBarContainer.addSubview(healthBarView)
        
        // Set fixed width for health bar container.
        let maxWidth: CGFloat = 300
        
        NSLayoutConstraint.activate([
            // Position container at top center.
            healthBarContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            healthBarContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            healthBarContainer.widthAnchor.constraint(equalToConstant: maxWidth),
            healthBarContainer.heightAnchor.constraint(equalToConstant: 20)
        ])
        
        // Health bar view constraints: align to container's left, top, bottom with a width we will update.
        healthBarWidthConstraint = healthBarView.widthAnchor.constraint(equalToConstant: maxWidth)
        NSLayoutConstraint.activate([
            healthBarView.leadingAnchor.constraint(equalTo: healthBarContainer.leadingAnchor),
            healthBarView.topAnchor.constraint(equalTo: healthBarContainer.topAnchor),
            healthBarView.bottomAnchor.constraint(equalTo: healthBarContainer.bottomAnchor),
            healthBarWidthConstraint
        ])
    }
    
    func updateBulletCountLabel(_ text: String) {
        bulletCountLabel.text = "Ammo: \(text)"
    }
    
    func updateHealthBar() {
        let maxWidth: CGFloat = 300
        let clampedHP = max(hp, 0)
        let newWidth = maxWidth * CGFloat(clampedHP) / 1000.0
        healthBarWidthConstraint.constant = newWidth
        view.layoutIfNeeded()
        
        damagePlayer?.play()
        flashRedEffect()
        
        if hp <= 0 {
            showDeathScreen()
        }
    }

    func flashRedEffect() {
        let redOverlay = UIView(frame: view.bounds)
        redOverlay.backgroundColor = UIColor.red
        redOverlay.alpha = 0.0
        view.addSubview(redOverlay)
        
        // Animate red flash.
        UIView.animate(withDuration: 0.1, animations: {
            redOverlay.alpha = 0.5
        }) { _ in
            UIView.animate(withDuration: 0.1, animations: {
                redOverlay.alpha = 0.0
            }) { _ in
                redOverlay.removeFromSuperview()
            }
        }
    }
    
    @objc func nightVisionSwitchChanged(_ sender: UISwitch) {
        nightVisionEnabled = sender.isOn
        nightVisionImageView.isHidden = !nightVisionEnabled
    }
    
    @objc func gunSelectorTapped() {
        print("gun selector tapped")
        let gunSelectorVC = GunSelectorViewController()
        gunSelectorVC.delegate = self
        present(gunSelectorVC, animated: true, completion: nil)
    }
    
    // Gesture handler for semi and full auto firing.
    @objc func handleFireGesture(_ gesture: UILongPressGestureRecognizer) {
        guard let gun = selectedGun else { return }
        if gun.isSemiAuto {
            if gesture.state == .began {
                shoot()
            }
        } else {
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
        multipeerService.send(message: "Hey friend 👋")
        
        if isReloading { return }
        if bulletCount > 0 {
            bulletCount -= 1
            updateBulletCountLabel("\(bulletCount)")
            
            let shootHaptic = UIImpactFeedbackGenerator(style: .medium)
            shootHaptic.impactOccurred()
            
            createBulletTracer()
            
            if isPersonInCrosshair() {
                let hitHaptic = UINotificationFeedbackGenerator()
                hitHaptic.notificationOccurred(.success)
                animateHitFeedback()
                hitmarkerPlayer?.play()
                sendHit()
            } else {
                missPlayer?.play()
            }
            
            if bulletCount == 0 {
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
    }
    
    func sendHit() {
        guard let selectedGun = selectedGun else { return }
        self.udp?.sendWhenReady(message: "hit: \(selectedGun.damagePerShot)")
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
    
    func triggerLocalNetworkPrompt() {
        let browser = NWBrowser(for: .bonjour(type: "_localservice._udp", domain: nil), using: .udp)
        browser.stateUpdateHandler = { state in
            print("NWBrowser state: \(state)")
        }
        browser.start(queue: .main)
    }
    
    func showDeathScreen() {
        // Create a full-screen red overlay.
        let deathView = UIView()
        deathView.translatesAutoresizingMaskIntoConstraints = false
        deathView.backgroundColor = UIColor.red
        view.addSubview(deathView)
        
        NSLayoutConstraint.activate([
            deathView.topAnchor.constraint(equalTo: view.topAnchor),
            deathView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            deathView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            deathView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        // Create the End Game button.
        let endGameButton = UIButton(type: .system)
        endGameButton.translatesAutoresizingMaskIntoConstraints = false
        endGameButton.setTitle("End Game", for: .normal)
        endGameButton.setTitleColor(.white, for: .normal)
        endGameButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 24)
        deathView.addSubview(endGameButton)
        
        NSLayoutConstraint.activate([
            endGameButton.centerXAnchor.constraint(equalTo: deathView.centerXAnchor),
            endGameButton.centerYAnchor.constraint(equalTo: deathView.centerYAnchor)
        ])
        
        endGameButton.addTarget(self, action: #selector(endGameButtonTapped), for: .touchUpInside)
    }
    
    @objc func endGameButtonTapped() {
        dismiss(animated: true, completion: nil)
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
    
    func createBulletTracer() {
        let startPoint = CGPoint(x: view.bounds.width - 30, y: view.bounds.height - 30)
        let endPoint = crosshairView.center

        let tracerPath = UIBezierPath()
        tracerPath.move(to: startPoint)
        tracerPath.addLine(to: endPoint)
        
        let tracerLayer = CAShapeLayer()
        tracerLayer.path = tracerPath.cgPath
        tracerLayer.strokeColor = UIColor.yellow.cgColor
        tracerLayer.lineWidth = 2.0
        tracerLayer.lineCap = .round
        tracerLayer.strokeEnd = 0
        
        view.layer.addSublayer(tracerLayer)
        
        let animationDuration: CFTimeInterval = 0.15
        let strokeAnimation = CABasicAnimation(keyPath: "strokeEnd")
        strokeAnimation.fromValue = 0
        strokeAnimation.toValue = 1
        strokeAnimation.duration = animationDuration
        strokeAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        tracerLayer.add(strokeAnimation, forKey: "strokeEndAnimation")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
            tracerLayer.removeFromSuperlayer()
        }
    }
}

extension BattleViewController: GunSelectorDelegate {
    func didSelectGun(_ gun: Gun) {
        selectedGun = gun
        gunSelectorLabel.text = "\(gun.name), \(gun.isSemiAuto ? "Semi-Auto" : "Full-Auto")"
        
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

extension BattleViewController: MultipeerServiceDelegate {
    func received(message: String, from peerID: MCPeerID) {
        print("Message from \(peerID.displayName): \(message)")
    }

    func peerDidConnect(_ peerID: MCPeerID) {
        print("Connected to: \(peerID.displayName)")
    }

    func peerDidDisconnect(_ peerID: MCPeerID) {
        print("Disconnected from: \(peerID.displayName)")
    }
}
