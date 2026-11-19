//
//  CustomPlaylistViewController.swift
//  SoundSpots
//
//  A playlist you made yourself: play it, reorder it, edit it.
//

import UIKit

final class CustomPlaylistViewController: UIViewController {

    /// Passed in from the Playlists tab. The id is used so edits made elsewhere show up here.
    var playlistID: UUID?

    @IBOutlet private weak var summaryLabel: UILabel!
    @IBOutlet private weak var playButton: UIButton!
    @IBOutlet private weak var tableView: UITableView!

    private let store = ListenStore.shared
    private var playlist: CustomPlaylist?
    private var observers: [NSObjectProtocol] = []

    deinit {
        observers.forEach { NotificationCenter.default.removeObserver($0) }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
        tableView.dataSource = self
        tableView.delegate = self
        playButton.setTitle(nil, for: .normal)

        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(title: "Edit Songs", image: UIImage(systemName: "square.and.pencil"),
                            primaryAction: UIAction { [weak self] _ in
                                self?.performSegue(withIdentifier: SegueIdentifier.showCreatePlaylist.rawValue, sender: nil)
                            }),
            editButtonItem
        ]

        let center = NotificationCenter.default
        observers.append(center.addObserver(forName: .listeningHistoryDidChange, object: nil, queue: .main) { [weak self] _ in
            self?.reload()
        })
        observers.append(center.addObserver(forName: .previewPlayerDidChange, object: nil, queue: .main) { [weak self] _ in
            self?.updatePlayButton()
        })
        reload()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParent { PreviewPlayer.shared.stop() }
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        tableView.setEditing(editing, animated: animated)
    }

    private func reload() {
        guard let id = playlistID, let playlist = store.playlist(withID: id) else {
            // The playlist was deleted while this screen was open.
            if playlistID != nil { navigationController?.popViewController(animated: true) }
            return
        }
        self.playlist = playlist
        title = playlist.name
        let count = playlist.songs.count
        summaryLabel.text = ["\(count) song\(count == 1 ? "" : "s")", playlist.durationText]
            .filter { !$0.isEmpty }
            .joined(separator: " • ")
        tableView.reloadData()
        updatePlayButton()
    }

    private func updatePlayButton() {
        var config = UIButton.Configuration.filled()
        config.cornerStyle = .capsule
        config.imagePadding = 6
        let first = playlist?.songs.first
        if let first = first, PreviewPlayer.shared.isPlaying(first) {
            config.title = "Stop"
            config.image = UIImage(systemName: "stop.fill")
        } else {
            config.title = "Play"
            config.image = UIImage(systemName: "play.fill")
        }
        playButton.configuration = config
        playButton.isEnabled = first?.previewURL != nil
    }

    @IBAction private func playTapped(_ sender: UIButton) {
        guard let first = playlist?.songs.first else { return }
        PreviewPlayer.shared.toggle(first)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch SegueIdentifier(rawValue: segue.identifier ?? "") {
        case .showSong:
            guard let songVC = segue.destination as? SongDetailViewController,
                  let song = sender as? Song else { return }
            songVC.song = song
        case .showCreatePlaylist:
            guard let nav = segue.destination as? UINavigationController,
                  let createVC = nav.topViewController as? CreatePlaylistViewController else { return }
            createVC.editingPlaylist = playlist
        default:
            break
        }
    }
}

extension CustomPlaylistViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        playlist?.songs.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: SongCell.reuseIdentifier,
                                                       for: indexPath) as? SongCell,
              let song = playlist?.songs[indexPath.row] else {
            return UITableViewCell()
        }
        let plays = store.totalPlays(of: song)
        cell.configure(with: song, detail: plays > 0 ? "▶︎ \(pluralized(plays, "play")) total" : nil, rank: indexPath.row + 1)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let song = playlist?.songs[indexPath.row] else { return }
        performSegue(withIdentifier: SegueIdentifier.showSong.rawValue, sender: song)
    }

    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        guard var updated = playlist else { return }
        let song = updated.songs.remove(at: sourceIndexPath.row)
        updated.songs.insert(song, at: destinationIndexPath.row)
        playlist = updated
        store.savePlaylist(updated)
    }

    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let remove = UIContextualAction(style: .destructive, title: "Remove") { [weak self] _, _, done in
            guard let self = self, var updated = self.playlist else { return done(false) }
            updated.songs.remove(at: indexPath.row)
            self.store.savePlaylist(updated)
            done(true)
        }
        remove.image = UIImage(systemName: "minus.circle")
        return UISwipeActionsConfiguration(actions: [remove])
    }

    func tableView(_ tableView: UITableView,
                   leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let song = playlist?.songs[indexPath.row], song.previewURL != nil else { return nil }
        let isPlaying = PreviewPlayer.shared.isPlaying(song)
        let action = UIContextualAction(style: .normal, title: isPlaying ? "Stop" : "Preview") { _, _, done in
            PreviewPlayer.shared.toggle(song)
            done(true)
        }
        action.image = UIImage(systemName: isPlaying ? "stop.fill" : "play.fill")
        action.backgroundColor = .brandPink
        return UISwipeActionsConfiguration(actions: [action])
    }
}
