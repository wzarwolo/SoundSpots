//
//  SceneDelegate.swift
//  SoundSpots
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        // The window and root view controller come from Main.storyboard.
        // Typecasting: a generic UIScene must be a UIWindowScene for this app.
        guard scene is UIWindowScene else { return }

        // Typecasting: the storyboard's initial view controller is a UITabBarController.
        guard let tabBarController = window?.rootViewController as? UITabBarController else { return }

        // Pattern-matching typecast: only loop over children that are navigation controllers.
        for case let navController as UINavigationController in tabBarController.viewControllers ?? [] {
            navController.navigationBar.prefersLargeTitles = true
        }
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        PreviewPlayer.shared.stop()
    }
}
