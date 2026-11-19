//
//  ReminderService.swift
//  SoundSpots
//
//  "Memory reminders": a local notification that fires when you arrive at one of your
//  spots, reminding you of the first song you heard there (or your own custom message).
//  Uses UNLocationNotificationTrigger, so no server is involved.
//

import UIKit
import CoreLocation
import UserNotifications

final class ReminderService: NSObject {

    static let shared = ReminderService()

    /// iOS monitors at most 20 regions per app.
    private let maxRegions = 20
    private let regionRadius: CLLocationDistance = 120
    private let identifierPrefix = "spot-reminder-"

    private let center = UNUserNotificationCenter.current()
    private let locationManager = CLLocationManager()
    private let store = ListenStore.shared
    private var observers: [NSObjectProtocol] = []

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    /// Call once at launch. Keeps reminders in sync with spots and settings from then on.
    func start() {
        center.delegate = self
        let notifications = NotificationCenter.default
        for name in [Notification.Name.listeningHistoryDidChange, .settingsDidChange] {
            observers.append(notifications.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                self?.reschedule()
            })
        }
        reschedule()
    }

    /// Asks for notification + location permission. The completion gets `true` if reminders can work.
    func requestPermission(completion: @escaping (Bool) -> Void) {
        center.requestAuthorization(options: [.alert, .sound]) { [weak self] granted, _ in
            DispatchQueue.main.async {
                if granted, self?.locationManager.authorizationStatus == .notDetermined {
                    // Location-based notifications need at least "While Using" location access.
                    self?.locationManager.requestWhenInUseAuthorization()
                }
                completion(granted)
            }
        }
    }

    /// Replaces every scheduled spot reminder with a fresh set for the current spots.
    func reschedule() {
        let settings = SettingsStore.shared.settings
        center.getPendingNotificationRequests { [weak self] requests in
            guard let self = self else { return }
            let oldIDs = requests.map { $0.identifier }.filter { $0.hasPrefix(self.identifierPrefix) }
            self.center.removePendingNotificationRequests(withIdentifiers: oldIDs)
            guard settings.remindersOn else { return }

            DispatchQueue.main.async {
                // Busiest spots first, since iOS only watches 20 regions.
                let spots = self.store.rankedPlaces()
                    .map { $0.item }
                    .filter { $0.wantsReminders }
                    .prefix(self.maxRegions)
                for place in spots {
                    self.schedule(for: place)
                }
            }
        }
    }

    /// Sends a reminder for the busiest spot in 5 seconds, so you can see what one looks like.
    func sendTestReminder(completion: @escaping (Bool) -> Void) {
        requestPermission { [weak self] granted in
            guard granted, let self = self,
                  let place = self.store.rankedPlaces().first?.item else {
                completion(false)
                return
            }
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
            let request = UNNotificationRequest(identifier: "test-reminder", content: self.content(for: place),
                                                trigger: trigger)
            self.center.add(request) { error in
                DispatchQueue.main.async { completion(error == nil) }
            }
        }
    }

    // MARK: Building reminders

    private func schedule(for place: Place) {
        let region = CLCircularRegion(center: place.coordinate.clCoordinate, radius: regionRadius,
                                      identifier: place.id.uuidString)
        region.notifyOnEntry = true
        region.notifyOnExit = false
        let trigger = UNLocationNotificationTrigger(region: region, repeats: true)
        let request = UNNotificationRequest(identifier: identifierPrefix + place.id.uuidString,
                                            content: content(for: place), trigger: trigger)
        center.add(request)
    }

    /// The "memory message": the user's own note if they wrote one, otherwise the first song heard here.
    func message(for place: Place) -> String {
        if let note = place.reminderNote?.trimmingCharacters(in: .whitespacesAndNewlines), !note.isEmpty {
            return note
        }
        if let first = store.oldestFirstListen(at: place) {
            return "Remember? You first heard “\(first.song.title)” by \(first.song.artist) here on \(dateFormatter.string(from: first.date))."
        }
        return "You're back at one of your SoundSpots. What are you listening to?"
    }

    private func content(for place: Place) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "🎧 Memory at \(place.displayName)"
        content.body = message(for: place)
        content.sound = .default
        content.userInfo = ["placeID": place.id.uuidString]
        return content
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension ReminderService: UNUserNotificationCenterDelegate {
    /// Show the banner even when the app is open.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .list, .sound])
    }
}
