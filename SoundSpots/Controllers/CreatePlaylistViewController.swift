//
//  CreatePlaylistViewController.swift
//  SoundSpots
//
//  Build your own playlist from the songs you've logged. Also used to edit one.
//

import UIKit

final class CreatePlaylistViewController: UIViewController {

    /// Set this to edit an existing playlist; leave nil to create a new one.
    var editingPlaylist: CustomPlaylist?

    @IBOutlet private weak var nameField: UITextField!
    @IBOutlet private weak var countLabel: UILabel!
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var emptyStateLabel: UILabel!

    private let store = ListenStore.shared
    private var songs: [Song] = []
    /// Selected song ids, in the order they were picked (that's the playlist order).
    private var selectedIDs: [Int] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        nameField.delegate = self
        nameField.addTarget(self, action: #selector(nameChanged), for: .editingChanged)

        songs = store.allSongs()
        if let playlist = editingPlaylist {
            title = "Edit Playlist"
            nameField.text = playlist.name
            selectedIDs = playlist.songs.map { $0.id }
            // Keep songs that are in the playlist even if they were later removed from history.
            let known = Set(songs.map { $0.id })
            songs += playlist.songs.filter { !known.contains($0.id) }
        } else {
            title = "New Playlist"
        }

        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self,
                                                           action: #selector(cancelTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self,
                                                            action: #selector(saveTapped))
        navigationItem.rightBarButtonItem?.style = .done
        setToolbarItems([UIBarButtonItem(title: "Fill from a Spot", image: UIImage(systemName: "wand.and.stars"),
                                         menu: makeFillMenu())], animated: false)
        navigationController?.isToolbarHidden = store.places.isEmpty

        emptyStateLabel.isHidden = !songs.isEmpty
        updateState()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if editingPlaylist == nil { nameField.becomeFirstResponder() }
    }

    private func updateState() {
        let count = selectedIDs.count
        countLabel.text = count == 0 ? "Tap songs to add them" : "\(count) song\(count == 1 ? "" : "s") selected"
        let hasName = !(nameField.text ?? "").trimmingCharacters(in: .whitespaces).isEmpty
        navigationItem.rightBarButtonItem?.isEnabled = hasName && count > 0
    }

    /// Quick-fill: select the top songs from one of your spots.
    private func makeFillMenu() -> UIMenu {
        let actions = store.rankedPlaces().map { ranked in
            UIAction(title: ranked.item.displayName, subtitle: pluralized(ranked.plays, "play")) { [weak self] _ in
                guard let self = self else { return }
                let top = PlaylistSort.mostPlayed.sorted(self.store.playlist(for: ranked.item)).prefix(10)
                for item in top where !self.selectedIDs.contains(item.song.id) {
                    self.selectedIDs.append(item.song.id)
                }
                if (self.nameField.text ?? "").isEmpty {
                    self.nameField.text = "\(ranked.item.name) Favorites"
                }
                self.tableView.reloadData()
                self.updateState()
            }
        }
        return UIMenu(title: "Add the top songs from…", children: actions)
    }

    // MARK: Actions

    @objc private func nameChanged() {
        updateState()
    }

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    @objc private func saveTapped() {
        let name = (nameField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let byID = Dictionary(songs.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let chosen = selectedIDs.compactMap { byID[$0] }
        guard !name.isEmpty, !chosen.isEmpty else { return }

        if var playlist = editingPlaylist {
            playlist.name = name
            playlist.songs = chosen
            store.savePlaylist(playlist)
        } else {
            store.savePlaylist(CustomPlaylist(name: name, songs: chosen))
        }
        dismiss(animated: true)
    }
}

// MARK: - Table

extension CreatePlaylistViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        songs.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: SongCell.reuseIdentifier,
                                                       for: indexPath) as? SongCell else {
            return UITableViewCell()
        }
        let song = songs[indexPath.row]
        let position = selectedIDs.firstIndex(of: song.id)
        cell.configure(with: song, detail: position.map { "#\($0 + 1) in playlist" })
        cell.accessoryType = position == nil ? .none : .checkmark
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let id = songs[indexPath.row].id
        if let index = selectedIDs.firstIndex(of: id) {
            selectedIDs.remove(at: index)
        } else {
            selectedIDs.append(id)
        }
        // Positions of other songs may shift, so refresh every visible row.
        tableView.reloadRows(at: tableView.indexPathsForVisibleRows ?? [indexPath], with: .none)
        updateState()
    }
}

extension CreatePlaylistViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
