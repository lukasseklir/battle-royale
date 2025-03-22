//
//  SceneDelegate.swift
//  BattleRoyale
//
//  Created by Lukas Seklir on 3/22/25.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        // Ensure we have a UIWindowScene to work with
        guard let windowScene = (scene as? UIWindowScene) else { return }

        // Create the window using the windowScene
        window = UIWindow(windowScene: windowScene)

        // Create your initial view controller (replace with your real VC)
        let initialViewController = InitialViewController()

        // Set root view controller and make window key and visible
        window?.rootViewController = initialViewController
        window?.makeKeyAndVisible()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Handle scene disconnection if needed
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Handle app becoming active
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Handle app resigning active
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Handle entering foreground
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Handle entering background
    }
}
