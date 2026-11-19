//
//  PlaylistViewController.swift
//  SoundSpots
//
//  The playlist for one place: the songs you play most there.
//

import UIKit

final class PlaylistViewController: UIViewController {

    /// Passed in from the map or the Playlists tab.
    var place: Place?

    @IBOutlet private weak var placeLabel: UILabel!
    @IBOutlet private weak var summaryLabel: UILabel!
    @IBOutlet private weak var sortControl: UISegmentedControl!
    @IBOutlet private weak var playTopButton: UIButton!
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var emptyStateLabel: UILabel!

    private let store = ListenStore.shared
    private var sort: PlaylistSort = .mostPlayed
    private var items: [PlaylistItem] = []
    private var observers: [NSObjectProtocol] = []

    deinit {
        observers.forEach { NotificationCenter.default.removeObserver($0) }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
        tableView.dataSource = self
        tableView.delegate = self
        playTopButton.setTitle(nil, for: .normal)
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Edit Spot", image: UIImage(systemName: "pencil"),
                                                            primaryAction: UIAction { [weak self] _ in
                                                                guard let self = self, let place = self.place else { return }
                                                                self.presentSpotEditor(for: place)
                                                            })

        for option in PlaylistSort.allCases where option.rawValue < sortControl.numberOfSegments {
            sortControl.setTitle(option.title, forSegmentAt: option.rawValue)
        }
        sortControl.selectedSegmentIndex = sort.rawValue

        let center = NotificationCenter.default
        observers.append(center.addObserver(forName: .listeningHistoryDidChange, object: nil, queue: .main) { [weak self] _ in
            self?.reload()
        })
        observers.append(center.addObserver(forName: .previewPlayerDidChange, object: nil, queue: .main) { [weak self] _ in
            self?.updatePlayButton()
        })
        reload()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let selected = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: selected, animated: animated)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParent { PreviewPlayer.shared.stop() }
    }

    private func reload() {
        // Re-read the spot so renames and emoji changes show up immediately.
        if let current = place.flatMap({ store.place(withID: $0.id) }) {
            place = current
        }
        guard let place = place else {
            placeLabel.text = "No place selected"
            return
        }
        title = "\(place.name) Mix"
        placeLabel.text = place.emoji == nil ? "📍 \(place.name)" : place.displayName

        let all = store.playlist(for: place)
        items = sort.sorted(all)
        let firsts = all.filter { $0.isFirstHeardHere }.count
        summaryLabel.text = "\(all.count) songs • \(store.playCount(for: place)) plays • \(firsts) first heard here"

        tableView.reloadData()
        emptyStateLabel.text = sort == .firstHeardHere
            ? "You haven't discovered any songs here yet."
            : "No songs logged here yet."
        emptyStateLabel.isHidden = !items.isEmpty
        updatePlayButton()
    }

    private func updatePlayButton() {
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = .brandPink
        config.cornerStyle = .capsule
        config.imagePadding = 6
        let top = items.first?.song
        if let top = top, PreviewPlayer.shared.isPlaying(top) {
            config.title = "Stop"
            config.image = UIImage(systemName: "stop.fill")
        } else {
            config.title = "Play #1"
            config.image = UIImage(systemName: "play.fill")
        }
        playTopButton.configuration = config
        playTopButton.isEnabled = top?.previewURL != nil
    }

    // MARK: Actions

    @IBAction private func sortChanged(_ sender: UISegmentedControl) {
        sort = PlaylistSort(rawValue: sender.selectedSegmentIndex) ?? .mostPlayed
        reload()
    }

    @IBAction private func playTopTapped(_ sender: UIButton) {
        guard let top = items.first?.song else { return }
        PreviewPlayer.shared.toggle(top)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == SegueIdentifier.showSong.rawValue,
              let songVC = segue.destination as? SongDetailViewController,
              let song = sender as? Song
        else { return }
        songVC.song = song
    }
}

extension PlaylistViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: SongCell.reuseIdentifier,
                                                       for: indexPath) as? SongCell else {
            return UITableViewCell()
        }
        let item = items[indexPath.row]
        var detail = "▶︎ \(item.playCount)× here"
        if item.isFirstHeardHere {
            detail += " • 🌟 First heard here"
        }
        cell.configure(with: item.song, detail: detail, rank: indexPath.row + 1)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: SegueIdentifier.showSong.rawValue, sender: items[indexPath.row].song)
    }

    /// Swipe right on a song to hear its preview.
    func tableView(_ tableView: UITableView,
                   leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let song = items[indexPath.row].song
        guard song.previewURL != nil else { return nil }
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
