//
//  PlacesViewController.swift
//  SoundSpots
//
//  Tab 3: playlists you made yourself, plus one auto-generated Mix per spot (busiest first).
//

import UIKit

final class PlacesViewController: UIViewController {

    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var emptyStateLabel: UILabel!

    private enum Section: Int, CaseIterable {
        case myPlaylists
        case spotMixes
    }

    private let store = ListenStore.shared
    private var places: [Place] = []
    private var playlists: [CustomPlaylist] = []
    private var historyObserver: NSObjectProtocol?
    private let cellID = "PlaceCell"

    deinit {
        if let observer = historyObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Create Playlist", image: UIImage(systemName: "plus"),
                                                            primaryAction: UIAction { [weak self] _ in
                                                                self?.createPlaylistTapped()
                                                            })
        historyObserver = NotificationCenter.default.addObserver(forName: .listeningHistoryDidChange,
                                                                 object: nil, queue: .main) { [weak self] _ in
            self?.reload()
        }
        reload()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let selected = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: selected, animated: animated)
        }
    }

    private func reload() {
        places = store.places.sorted { store.playCount(for: $0) > store.playCount(for: $1) }
        playlists = store.customPlaylists
        tableView.reloadData()
        emptyStateLabel.isHidden = !places.isEmpty
    }

    private func createPlaylistTapped() {
        guard !store.listens.isEmpty else {
            showMessage(title: "Log a song first",
                        message: "Playlists are built from the songs you've logged. Tap ＋ on the Map to log one.")
            return
        }
        performSegue(withIdentifier: SegueIdentifier.showCreatePlaylist.rawValue, sender: nil)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch SegueIdentifier(rawValue: segue.identifier ?? "") {
        case .showPlaylist:
            guard let playlistVC = segue.destination as? PlaylistViewController,
                  let place = sender as? Place else { return }
            playlistVC.place = place
        case .showCustomPlaylist:
            guard let customVC = segue.destination as? CustomPlaylistViewController,
                  let playlist = sender as? CustomPlaylist else { return }
            customVC.playlistID = playlist.id
        case .showCreatePlaylist:
            // Editing an existing playlist passes it along; creating passes nil.
            guard let nav = segue.destination as? UINavigationController,
                  let createVC = nav.topViewController as? CreatePlaylistViewController else { return }
            createVC.editingPlaylist = sender as? CustomPlaylist
        default:
            break
        }
    }
}

extension PlacesViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        Section.allCases.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Section(rawValue: section) {
        case .myPlaylists: return "My Playlists"
        case .spotMixes: return places.isEmpty ? nil : "Spot Mixes"
        case .none: return nil
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section) {
        case .myPlaylists: return playlists.count + 1   // +1 for the "Create Playlist" row
        case .spotMixes: return places.count
        case .none: return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath)
        var content = UIListContentConfiguration.subtitleCell()
        content.secondaryTextProperties.color = .secondaryLabel
        cell.accessoryType = .disclosureIndicator

        switch Section(rawValue: indexPath.section) {
        case .myPlaylists where indexPath.row == playlists.count:
            content.image = UIImage(systemName: "plus.circle.fill")
            content.text = "Create Playlist"
            content.textProperties.color = view.tintColor
            content.textProperties.font = .preferredFont(forTextStyle: .headline)
            cell.accessoryType = .none

        case .myPlaylists:
            let playlist = playlists[indexPath.row]
            content.image = UIImage(systemName: "music.note.list")
            content.imageProperties.tintColor = .systemIndigo
            content.text = playlist.name
            content.textProperties.font = .preferredFont(forTextStyle: .headline)
            content.secondaryText = [pluralized(playlist.songs.count, "song"), playlist.durationText]
                .filter { !$0.isEmpty }
                .joined(separator: " • ")

        case .spotMixes:
            let place = places[indexPath.row]
            let songCount = store.playlist(for: place).count
            content.image = UIImage(systemName: "mappin.and.ellipse")
            content.imageProperties.tintColor = .brandPink
            content.text = "\(place.displayName) Mix"
            content.textProperties.font = .preferredFont(forTextStyle: .headline)
            content.secondaryText = "\(pluralized(songCount, "song")) • \(pluralized(store.playCount(for: place), "play"))"
                + (store.topSong(at: place).map { " • Top: \($0.title)" } ?? "")

        case .none:
            break
        }
        cell.contentConfiguration = content
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch Section(rawValue: indexPath.section) {
        case .myPlaylists where indexPath.row == playlists.count:
            tableView.deselectRow(at: indexPath, animated: true)
            createPlaylistTapped()
        case .myPlaylists:
            performSegue(withIdentifier: SegueIdentifier.showCustomPlaylist.rawValue, sender: playlists[indexPath.row])
        case .spotMixes:
            performSegue(withIdentifier: SegueIdentifier.showPlaylist.rawValue, sender: places[indexPath.row])
        case .none:
            break
        }
    }

    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        switch Section(rawValue: indexPath.section) {
        case .myPlaylists where indexPath.row < playlists.count:
            let playlist = playlists[indexPath.row]
            let delete = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, done in
                self?.store.deletePlaylist(playlist)
                done(true)
            }
            delete.image = UIImage(systemName: "trash")
            let edit = UIContextualAction(style: .normal, title: "Edit") { [weak self] _, _, done in
                self?.performSegue(withIdentifier: SegueIdentifier.showCreatePlaylist.rawValue, sender: playlist)
                done(true)
            }
            edit.image = UIImage(systemName: "square.and.pencil")
            edit.backgroundColor = .systemIndigo
            return UISwipeActionsConfiguration(actions: [delete, edit])

        case .spotMixes:
            let place = places[indexPath.row]
            let delete = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, done in
                self?.store.deletePlace(place)
                done(true)
            }
            delete.image = UIImage(systemName: "trash")
            let edit = UIContextualAction(style: .normal, title: "Edit") { [weak self] _, _, done in
                self?.presentSpotEditor(for: place)
                done(true)
            }
            edit.image = UIImage(systemName: "pencil")
            edit.backgroundColor = .systemOrange
            return UISwipeActionsConfiguration(actions: [delete, edit])

        default:
            return nil
        }
    }
}
