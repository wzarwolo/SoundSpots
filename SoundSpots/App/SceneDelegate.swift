//
//  SceneDelegate.swift
//  SoundSpots
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    private var settingsObserver: NSObjectProtocol?

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

        // Light/dark mode and accent color come from Settings, and update live when changed.
        applyAppearance()
        settingsObserver = NotificationCenter.default.addObserver(forName: .settingsDidChange,
                                                                  object: nil, queue: .main) { [weak self] _ in
            self?.applyAppearance()
        }
    }

    private func applyAppearance() {
        guard let window = window else { return }
        UIView.transition(with: window, duration: 0.25, options: .transitionCrossDissolve) {
            SettingsStore.shared.applyAppearance(to: [window])
        }
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        PreviewPlayer.shared.stop()
    }
}
