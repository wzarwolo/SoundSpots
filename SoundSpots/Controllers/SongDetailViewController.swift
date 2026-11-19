//
//  SongDetailViewController.swift
//  SoundSpots
//
//  Shows a song, a map of where you first heard it, and plays the iTunes preview.
//

import UIKit
import MapKit

final class SongDetailViewController: UIViewController {

    /// Passed in by the previous screen.
    var song: Song?

    @IBOutlet private weak var artworkImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var artistLabel: UILabel!
    @IBOutlet private weak var albumLabel: UILabel!
    @IBOutlet private weak var previewButton: UIButton!
    @IBOutlet private weak var firstHeardLabel: UILabel!
    @IBOutlet private weak var mapView: MKMapView!
    @IBOutlet private weak var statsLabel: UILabel!

    private let store = ListenStore.shared
    private var playerObserver: NSObjectProtocol?

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter
    }()

    deinit {
        if let observer = playerObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
        artworkImageView.layer.cornerRadius = 16
        artworkImageView.clipsToBounds = true
        mapView.layer.cornerRadius = 12
        previewButton.setTitle(nil, for: .normal)   // the button configuration supplies the title

        guard let song = song else {
            titleLabel.text = "No song selected"
            previewButton.isEnabled = false
            return
        }
        populate(with: song)
        updatePreviewButton()
        SettingsStore.shared.settings.mapStyle.apply(to: mapView)
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Memory Box", image: UIImage(systemName: "archivebox"),
                                                            primaryAction: UIAction { [weak self] _ in
                                                                self?.performSegue(withIdentifier: SegueIdentifier.showMemoryBox.rawValue, sender: song)
                                                            })

        playerObserver = NotificationCenter.default.addObserver(forName: .previewPlayerDidChange,
                                                                object: nil, queue: .main) { [weak self] _ in
            self?.updatePreviewButton()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let song = song, PreviewPlayer.shared.isPlaying(song) {
            PreviewPlayer.shared.stop()
        }
    }

    private func populate(with song: Song) {
        title = song.title
        titleLabel.text = song.title
        artistLabel.text = song.artist
        albumLabel.text = song.detailText

        artworkImageView.image = UIImage(systemName: "music.note")
        artworkImageView.tintColor = .tertiaryLabel
        ImageLoader.shared.loadImage(from: song.artworkURL(size: 600)) { [weak self] image in
            if let image = image { self?.artworkImageView.image = image }
        }

        // Every place this song has been played gets a pin; the first one is highlighted.
        let listens = store.listens.filter { $0.song.id == song.id }
        let placeIDs = Set(listens.map { $0.placeID })
        let places = store.places.filter { placeIDs.contains($0.id) }

        if let first = store.firstListen(of: song), let firstPlace = store.place(withID: first.placeID) {
            firstHeardLabel.text = "First heard at \(firstPlace.displayName)\n\(dateFormatter.string(from: first.date))"
        } else {
            firstHeardLabel.text = "You haven't logged this song yet."
        }

        let annotations = places.map { place in
            PlaceAnnotation(place: place,
                            playCount: listens.filter { $0.placeID == place.id }.count,
                            topSong: nil)
        }
        mapView.addAnnotations(annotations)
        if annotations.count == 1, let only = annotations.first {
            // showAnnotations zooms all the way in for a single pin; use a neighborhood-sized view.
            mapView.setRegion(MKCoordinateRegion(center: only.coordinate,
                                                 latitudinalMeters: 1_500, longitudinalMeters: 1_500), animated: false)
        } else {
            mapView.showAnnotations(annotations, animated: false)
        }
        if let first = store.firstListen(of: song),
           let firstPin = annotations.first(where: { $0.place.id == first.placeID }) {
            mapView.selectAnnotation(firstPin, animated: false)
        }
        mapView.isHidden = annotations.isEmpty

        statsLabel.text = "▶︎ Played \(listens.count) time\(listens.count == 1 ? "" : "s") at \(places.count) spot\(places.count == 1 ? "" : "s")"
    }

    private func updatePreviewButton() {
        guard let song = song else { return }
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = .brandPink
        config.cornerStyle = .capsule
        config.imagePadding = 8

        if song.previewURL == nil {
            config.title = "No Preview Available"
            previewButton.isEnabled = false
        } else if PreviewPlayer.shared.isPlaying(song) {
            config.title = "Stop Preview"
            config.image = UIImage(systemName: "stop.fill")
        } else {
            config.title = "Play 30s Preview"
            config.image = UIImage(systemName: "play.fill")
        }
        previewButton.configuration = config
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == SegueIdentifier.showMemoryBox.rawValue,
              let memoryVC = segue.destination as? MemoryBoxViewController,
              let song = sender as? Song
        else { return }
        memoryVC.song = song
    }

    @IBAction private func previewTapped(_ sender: UIButton) {
        guard let song = song else { return }
        PreviewPlayer.shared.toggle(song)
    }
}
