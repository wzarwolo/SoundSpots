//
//  SettingsViewController.swift
//  SoundSpots
//
//  Customize the app: light/dark mode, accent color, map style, memory reminders,
//  your spots' names and emoji, and whether friends show on the map.
//

import UIKit

final class SettingsViewController: UIViewController {

    @IBOutlet private weak var tableView: UITableView!

    private enum Section: Int, CaseIterable {
        case appearance, map, reminders, spots, friends

        var title: String {
            switch self {
            case .appearance: return "Appearance"
            case .map: return "Map Style"
            case .reminders: return "Memory Reminders"
            case .spots: return "Your Spots"
            case .friends: return "Friends"
            }
        }

        var footer: String? {
            switch self {
            case .reminders:
                return "When you arrive at a spot, SoundSpots sends a memory message: your own note, or the first song you heard there. Up to 20 of your busiest spots."
            case .spots:
                return "Tap a spot to rename it, give it an emoji, or write its memory message."
            case .friends:
                return "Friends are simulated for now. Real friend syncing needs accounts and is planned for a later version."
            default:
                return nil
            }
        }
    }

    private let settingsStore = SettingsStore.shared
    private let store = ListenStore.shared
    private let cellID = "SettingCell"
    private var places: [Place] = []
    private var observers: [NSObjectProtocol] = []

    private var settings: AppSettings { settingsStore.settings }

    deinit {
        observers.forEach { NotificationCenter.default.removeObserver($0) }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Settings"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellID)
        tableView.dataSource = self
        tableView.delegate = self
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self,
                                                            action: #selector(doneTapped))

        let center = NotificationCenter.default
        for name in [Notification.Name.settingsDidChange, .listeningHistoryDidChange] {
            observers.append(center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                self?.reload()
            })
        }
        reload()
    }

    private func reload() {
        places = store.rankedPlaces().map { $0.item } + store.places.filter { store.playCount(for: $0) == 0 }
        tableView.reloadData()
    }

    @objc private func doneTapped() {
        dismiss(animated: true)
    }

    // MARK: Controls

    @objc private func themeChanged(_ sender: UISegmentedControl) {
        guard let theme = AppTheme(rawValue: sender.selectedSegmentIndex) else { return }
        settingsStore.update { $0.theme = theme }
        settingsStore.applyAppearance(to: view.window.map { [$0] } ?? [])
    }

    @objc private func remindersSwitched(_ sender: UISwitch) {
        guard sender.isOn else {
            settingsStore.update { $0.remindersOn = false }
            return
        }
        ReminderService.shared.requestPermission { [weak self] granted in
            guard let self = self else { return }
            if granted {
                self.settingsStore.update { $0.remindersOn = true }
            } else {
                sender.setOn(false, animated: true)
                self.showMessage(title: "Notifications are off",
                                 message: "Turn on notifications for SoundSpots in the Settings app to get memory reminders.")
            }
        }
    }

    @objc private func spotReminderSwitched(_ sender: UISwitch) {
        guard places.indices.contains(sender.tag) else { return }
        var place = places[sender.tag]
        place.remindersEnabled = sender.isOn
        store.updatePlace(place)
    }

    @objc private func friendsSwitched(_ sender: UISwitch) {
        settingsStore.update { $0.showFriendsOnMap = sender.isOn }
    }

    private func sendTestReminder() {
        ReminderService.shared.sendTestReminder { [weak self] sent in
            if sent {
                self?.showMessage(title: "Test reminder on its way",
                                  message: "It arrives in about 5 seconds. You can stay in the app to see it.")
            } else {
                self?.showMessage(title: "Couldn't send a reminder",
                                  message: "Log at least one spot and allow notifications for SoundSpots.")
            }
        }
    }

    // MARK: Cell helpers

    private func switchView(isOn: Bool, tag: Int = 0, action: Selector) -> UISwitch {
        let toggle = UISwitch()
        toggle.isOn = isOn
        toggle.tag = tag
        toggle.addTarget(self, action: action, for: .valueChanged)
        return toggle
    }

    private func swatch(for color: UIColor) -> UIImage? {
        UIImage(systemName: "circle.fill")?.withTintColor(color, renderingMode: .alwaysOriginal)
    }
}

// MARK: - Table

extension SettingsViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        Section.allCases.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        Section(rawValue: section)?.title
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        Section(rawValue: section)?.footer
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section) {
        case .appearance: return 1 + AccentChoice.allCases.count
        case .map: return MapStyle.allCases.count
        case .reminders: return settings.remindersOn ? 2 + places.count : 2
        case .spots: return max(places.count, 1)
        case .friends: return 1
        case .none: return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath)
        cell.accessoryView = nil
        cell.accessoryType = .none
        cell.selectionStyle = .default
        var content = UIListContentConfiguration.valueCell()

        switch Section(rawValue: indexPath.section) {
        case .appearance:
            if indexPath.row == 0 {
                content.text = "Theme"
                content.image = UIImage(systemName: "circle.lefthalf.filled")
                let control = UISegmentedControl(items: AppTheme.allCases.map { $0.title })
                control.selectedSegmentIndex = settings.theme.rawValue
                control.addTarget(self, action: #selector(themeChanged(_:)), for: .valueChanged)
                cell.accessoryView = control
                cell.selectionStyle = .none
            } else {
                let accent = AccentChoice.allCases[indexPath.row - 1]
                content.text = accent.title
                content.image = swatch(for: accent.color)
                cell.accessoryType = accent == settings.accent ? .checkmark : .none
            }

        case .map:
            let style = MapStyle.allCases[indexPath.row]
            content.text = style.title
            content.image = UIImage(systemName: style.symbolName)
            cell.accessoryType = style == settings.mapStyle ? .checkmark : .none

        case .reminders:
            if indexPath.row == 0 {
                content.text = "Remind me at my spots"
                content.image = UIImage(systemName: "bell.badge")
                cell.accessoryView = switchView(isOn: settings.remindersOn, action: #selector(remindersSwitched(_:)))
                cell.selectionStyle = .none
            } else if indexPath.row == 1 {
                content.text = "Send a Test Reminder"
                content.textProperties.color = view.tintColor
                content.image = UIImage(systemName: "paperplane")
            } else {
                let index = indexPath.row - 2
                let place = places[index]
                content.text = place.displayName
                content.secondaryText = place.reminderNote == nil ? "First-song memory" : "Custom message"
                content.image = UIImage(systemName: "mappin.circle")
                cell.accessoryView = switchView(isOn: place.wantsReminders, tag: index,
                                                action: #selector(spotReminderSwitched(_:)))
                cell.selectionStyle = .none
            }

        case .spots:
            if places.isEmpty {
                content.text = "No spots yet"
                content.textProperties.color = .secondaryLabel
                cell.selectionStyle = .none
            } else {
                let place = places[indexPath.row]
                content.text = place.displayName
                content.secondaryText = pluralized(store.playCount(for: place), "play")
                content.image = UIImage(systemName: place.emoji == nil ? "mappin.and.ellipse" : "face.smiling")
                cell.accessoryType = .disclosureIndicator
            }

        case .friends:
            content.text = "Show friends on the map"
            content.image = UIImage(systemName: "person.2")
            cell.accessoryView = switchView(isOn: settings.showFriendsOnMap, action: #selector(friendsSwitched(_:)))
            cell.selectionStyle = .none

        case .none:
            break
        }

        cell.contentConfiguration = content
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch Section(rawValue: indexPath.section) {
        case .appearance where indexPath.row > 0:
            let accent = AccentChoice.allCases[indexPath.row - 1]
            settingsStore.update { $0.accent = accent }
            settingsStore.applyAppearance(to: view.window.map { [$0] } ?? [])
        case .map:
            let style = MapStyle.allCases[indexPath.row]
            settingsStore.update { $0.mapStyle = style }
        case .reminders where indexPath.row == 1:
            sendTestReminder()
        case .spots where !places.isEmpty:
            presentSpotEditor(for: places[indexPath.row])
        default:
            break
        }
    }
}
