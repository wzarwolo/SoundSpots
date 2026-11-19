//
//  MemoryBoxViewController.swift
//  SoundSpots
//
//  A memory box for one song: notes and photos about what was happening when you heard it.
//

import UIKit

final class MemoryBoxViewController: UIViewController {

    /// Passed in from Song Detail.
    var song: Song?

    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var emptyStateLabel: UILabel!

    private let store = ListenStore.shared
    private let photoCapture = PhotoCapture()
    private var memories: [Memory] = []
    private var historyObserver: NSObjectProtocol?

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    deinit {
        if let observer = historyObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
        title = "Memory Box"
        tableView.register(MemoryCell.self, forCellReuseIdentifier: MemoryCell.reuseIdentifier)
        tableView.dataSource = self
        tableView.delegate = self

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Add Memory", image: UIImage(systemName: "plus"),
                                                            menu: makeAddMenu())

        historyObserver = NotificationCenter.default.addObserver(forName: .listeningHistoryDidChange,
                                                                 object: nil, queue: .main) { [weak self] _ in
            self?.reload()
        }
        reload()
    }

    private func reload() {
        guard let song = song else { return }
        memories = store.memories(for: song)
        tableView.reloadData()
        emptyStateLabel.isHidden = !memories.isEmpty
    }

    private func makeAddMenu() -> UIMenu {
        var actions = [
            UIAction(title: "Write a Note", image: UIImage(systemName: "square.and.pencil")) { [weak self] _ in
                self?.promptForNote(photoFileName: nil)
            },
            UIAction(title: "Choose Photo", image: UIImage(systemName: "photo.on.rectangle")) { [weak self] _ in
                self?.addPhoto(from: .library)
            }
        ]
        if PhotoCapture.isCameraAvailable {
            actions.insert(UIAction(title: "Take Photo", image: UIImage(systemName: "camera")) { [weak self] _ in
                self?.addPhoto(from: .camera)
            }, at: 1)
        }
        return UIMenu(children: actions)
    }

    private func addPhoto(from source: PhotoCapture.Source) {
        photoCapture.present(from: self, source: source) { [weak self] image in
            guard let image = image else { return }
            guard let fileName = PhotoStore.shared.save(image) else {
                self?.showMessage(title: "Couldn't save the photo", message: "Please try again.")
                return
            }
            self?.promptForNote(photoFileName: fileName)
        }
    }

    /// Asks for a note. With a photo the note is optional ("Skip" still saves the photo).
    private func promptForNote(photoFileName: String?) {
        guard let song = song else { return }
        let hasPhoto = photoFileName != nil
        let alert = UIAlertController(title: hasPhoto ? "Add a caption?" : "New Memory",
                                      message: "What do you remember about hearing “\(song.title)”?",
                                      preferredStyle: .alert)
        alert.addTextField { field in
            field.placeholder = "Who were you with? What was happening?"
            field.autocapitalizationType = .sentences
        }
        alert.addAction(UIAlertAction(title: hasPhoto ? "Skip" : "Cancel", style: .cancel) { [weak self] _ in
            if let fileName = photoFileName {
                self?.saveMemory(text: nil, photoFileName: fileName)
            }
        })
        alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak self, weak alert] _ in
            let text = alert?.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !text.isEmpty || photoFileName != nil else { return }
            self?.saveMemory(text: text.isEmpty ? nil : text, photoFileName: photoFileName)
        })
        present(alert, animated: true)
    }

    private func saveMemory(text: String?, photoFileName: String?) {
        guard let song = song else { return }
        // Attach the memory to the spot where the song was first heard.
        let placeID = store.firstListen(of: song)?.placeID
        store.addMemory(Memory(songID: song.id, text: text, imageFileName: photoFileName, placeID: placeID))
    }
}

// MARK: - Table

extension MemoryBoxViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int { 1 }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let song = song else { return nil }
        guard let first = store.firstListen(of: song), let place = store.place(withID: first.placeID) else {
            return "\(song.title) • \(song.artist)"
        }
        return "\(song.title) • first heard at \(place.name)"
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        memories.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: MemoryCell.reuseIdentifier,
                                                       for: indexPath) as? MemoryCell else {
            return UITableViewCell()
        }
        let memory = memories[indexPath.row]
        let placeName = memory.placeID.flatMap { store.place(withID: $0) }?.displayName
        cell.configure(with: memory, placeName: placeName, dateText: dateFormatter.string(from: memory.date))
        return cell
    }

    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let memory = memories[indexPath.row]
        let delete = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, done in
            self?.store.deleteMemory(memory)
            done(true)
        }
        delete.image = UIImage(systemName: "trash")
        return UISwipeActionsConfiguration(actions: [delete])
    }
}
