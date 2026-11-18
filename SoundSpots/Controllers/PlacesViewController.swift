//
//  PlacesViewController.swift
//  SoundSpots
//
//  Tab 3: one auto-generated playlist per place, busiest places first.
//

import UIKit

final class PlacesViewController: UIViewController {

    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var emptyStateLabel: UILabel!

    private let store = ListenStore.shared
    private var places: [Place] = []
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
        tableView.reloadData()
        emptyStateLabel.isHidden = !places.isEmpty
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == SegueIdentifier.showPlaylist.rawValue,
              let playlistVC = segue.destination as? PlaylistViewController,
              let place = sender as? Place
        else { return }
        playlistVC.place = place
    }
}

extension PlacesViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        places.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath)
        let place = places[indexPath.row]
        let songCount = store.playlist(for: place).count

        var content = UIListContentConfiguration.subtitleCell()
        content.image = UIImage(systemName: "music.note.list")
        content.imageProperties.tintColor = .brandPink
        content.text = "\(place.name) Mix"
        content.textProperties.font = .preferredFont(forTextStyle: .headline)
        content.secondaryText = "\(songCount) songs • \(store.playCount(for: place)) plays"
            + (store.topSong(at: place).map { " • Top: \($0.title)" } ?? "")
        content.secondaryTextProperties.color = .secondaryLabel
        cell.contentConfiguration = content
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: SegueIdentifier.showPlaylist.rawValue, sender: places[indexPath.row])
    }

    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let place = places[indexPath.row]
        let delete = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, done in
            self?.store.deletePlace(place)
            done(true)
        }
        delete.image = UIImage(systemName: "trash")
        return UISwipeActionsConfiguration(actions: [delete])
    }
}
