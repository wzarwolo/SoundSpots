//
//  SettingsStore.swift
//  SoundSpots
//
//  The user's preferences, saved to UserDefaults as one Codable value.
//

import UIKit

extension Notification.Name {
    /// Posted when any setting changes so screens can restyle themselves.
    static let settingsDidChange = Notification.Name("settingsDidChange")
}

struct AppSettings: Codable, Equatable {
    var theme: AppTheme = .system
    var accent: AccentChoice = .pink
    var mapStyle: MapStyle = .standard
    var remindersOn: Bool = false
    var showFriendsOnMap: Bool = true
}

final class SettingsStore {

    static let shared = SettingsStore()

    private let defaults: UserDefaults
    private let storageKey = "app.settings.v1"

    private(set) var settings: AppSettings

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.settings = defaults.codable(AppSettings.self, forKey: storageKey) ?? AppSettings()
    }

    /// Changes settings through a closure, then saves and notifies once.
    func update(_ change: (inout AppSettings) -> Void) {
        var copy = settings
        change(&copy)
        guard copy != settings else { return }
        settings = copy
        defaults.setCodable(settings, forKey: storageKey)
        NotificationCenter.default.post(name: .settingsDidChange, object: self)
    }

    /// Applies light/dark mode and the accent color to every open window.
    func applyAppearance(to windows: [UIWindow]) {
        for window in windows {
            window.overrideUserInterfaceStyle = settings.theme.interfaceStyle
            window.tintColor = settings.accent.color
        }
        UISegmentedControl.appearance().selectedSegmentTintColor = settings.accent.color
    }
}
