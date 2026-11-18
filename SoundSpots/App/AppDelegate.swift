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
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    private func configureAppearance() {
        let tint = UIColor.brandPink
        UINavigationBar.appearance().tintColor = tint
        UITabBar.appearance().tintColor = tint
        UISegmentedControl.appearance().selectedSegmentTintColor = tint
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
    }
}

extension UIColor {
    /// The app's accent color (same as AccentColor in the asset catalog).
    static let brandPink = UIColor(red: 0.98, green: 0.20, blue: 0.40, alpha: 1)
}
