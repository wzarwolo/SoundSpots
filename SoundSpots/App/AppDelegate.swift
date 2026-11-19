//
//  AppDelegate.swift
//  SoundSpots
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        configureAppearance()
        ReminderService.shared.start()
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    private func configureAppearance() {
        // Bars and controls follow the window's tint, which is the user's accent color (see SceneDelegate).
        UISegmentedControl.appearance().selectedSegmentTintColor = .brandPink
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
    }
}

extension UIColor {
    /// The app's accent color. Pink by default; the user can change it in Settings.
    static var brandPink: UIColor { SettingsStore.shared.settings.accent.color }
}
