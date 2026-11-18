//
//  LogListenViewController.swift
//  SoundSpots
//
//  Modal step 1: search iTunes for the song you're listening to.
//

import UIKit

/// Custom protocol used to send the new listen back to whoever presented the modal.
protocol LogListenDelegate: AnyObject {
    func logListen(_ controller: UIViewController, didLog song: Song, at coordinate: Coordinate, placeName: String)
    func logListenDidCancel(_ controller: UIViewController)
}

final class LogListenViewController: UIViewController {

    // MARK: Passed in by MapViewController

    weak var delegate: LogListenDelegate?
    var fallbackCoordinate: Coordinate?

    // MARK: Outlets

    @IBOutlet private weak var searchBar: UISearchBar!
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet private weak var messageLabel: UILabel!

    // MARK: State

    private var service: MusicSearching = ITunesMusicService()
    private var results: [Song] = []
    private var searchDebounce: Timer?
    private var latestQuery = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
        tableView.dataSource = self
        tableView.delegate = self
        tableView.keyboardDismissMode = .onDrag
        messageLabel.text = "What are you listening to?\nSearch by song or artist."
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if results.isEmpty {
            searchBar.becomeFirstResponder()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let selected = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: selected, animated: animated)
        }
    }

    @IBAction private func cancelTapped(_ sender: UIBarButtonItem) {
        delegate?.logListenDidCancel(self)
    }

    // MARK: Searching

    private func search(_ term: String) {
        let query = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            results = []
            tableView.reloadData()
            messageLabel.isHidden = false
            return
        }
        latestQuery = query
        activityIndicator.startAnimating()
        messageLabel.isHidden = true

        service.searchSongs(matching: query) { [weak self] result in
            // Ignore slow responses for an older query.
            guard let self = self, query == self.latestQuery else { return }
            self.activityIndicator.stopAnimating()

            switch result {
            case .success(let songs):
                self.results = songs
                self.tableView.reloadData()
                self.messageLabel.text = "No songs found for “\(query)”."
                self.messageLabel.isHidden = !songs.isEmpty
            case .failure(let error):
                self.showError(error, for: query)
            }
        }
    }

    private func showError(_ error: NetworkError, for query: String) {
        let alert = UIAlertController(title: "Search failed", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Retry", style: .default) { [weak self] _ in
            self?.search(query)
        })
        alert.addAction(UIAlertAction(title: "Use Sample Songs", style: .default) { [weak self] _ in
            // Swap in the mock. This works because both types conform to MusicSearching.
            self?.service = MockMusicService()
            self?.search(query)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    // MARK: Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == SegueIdentifier.showConfirmListen.rawValue,
              let confirmVC = segue.destination as? ConfirmListenViewController,
              let song = sender as? Song
        else { return }
        // Pass everything forward, including the delegate, so step 2 can report back to the map.
        confirmVC.song = song
        confirmVC.fallbackCoordinate = fallbackCoordinate
        confirmVC.delegate = delegate
    }
}

// MARK: - UISearchBarDelegate

extension LogListenViewController: UISearchBarDelegate {

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // Wait until the user pauses typing so we don't send a request per keystroke.
        searchDebounce?.invalidate()
        searchDebounce = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            self?.search(searchText)
        }
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchDebounce?.invalidate()
        searchBar.resignFirstResponder()
        search(searchBar.text ?? "")
    }
}

// MARK: - UITableViewDataSource & Delegate

extension LogListenViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        results.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: SongCell.reuseIdentifier,
                                                       for: indexPath) as? SongCell else {
            return UITableViewCell()
        }
        let song = results[indexPath.row]
        let detail = ListenStore.shared.firstListen(of: song).flatMap { first in
            ListenStore.shared.place(withID: first.placeID).map { "Already logged • first heard at \($0.name)" }
        }
        cell.configure(with: song, detail: detail ?? song.album)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: SegueIdentifier.showConfirmListen.rawValue, sender: results[indexPath.row])
    }
}
