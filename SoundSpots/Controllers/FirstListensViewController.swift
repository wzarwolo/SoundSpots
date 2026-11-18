//
//  FirstListensViewController.swift
//  SoundSpots
//
//  Tab 2: every song you've logged, with where and when you first heard it.
//

import UIKit

final class FirstListensViewController: UIViewController {

    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var emptyStateLabel: UILabel!

    private let store = ListenStore.shared
    private var firstListens: [ListenEvent] = []
    private var historyObserver: NSObjectProtocol?

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

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
        firstListens = store.firstListens()
        tableView.reloadData()
        emptyStateLabel.isHidden = !firstListens.isEmpty
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == SegueIdentifier.showSong.rawValue,
              let songVC = segue.destination as? SongDetailViewController,
              let song = sender as? Song
        else { return }
        songVC.song = song
    }
}

extension FirstListensViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        firstListens.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: SongCell.reuseIdentifier,
                                                       for: indexPath) as? SongCell else {
            return UITableViewCell()
        }
        let listen = firstListens[indexPath.row]
        let placeName = store.place(withID: listen.placeID)?.name ?? "Unknown spot"
        cell.configure(with: listen.song,
                       detail: "📍 \(placeName) • \(dateFormatter.string(from: listen.date))")
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: SegueIdentifier.showSong.rawValue, sender: firstListens[indexPath.row].song)
    }
}
