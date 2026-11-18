//
//  ConfirmListenViewController.swift
//  SoundSpots
//
//  Modal step 2: figure out where you are, let you name the spot, then save.
//

import UIKit
import MapKit

final class ConfirmListenViewController: UIViewController {

    // MARK: Passed in by LogListenViewController

    var song: Song?
    var fallbackCoordinate: Coordinate?
    weak var delegate: LogListenDelegate?

    // MARK: Outlets

    @IBOutlet private weak var artworkImageView: UIImageView!
    @IBOutlet private weak var songTitleLabel: UILabel!
    @IBOutlet private weak var artistLabel: UILabel!
    @IBOutlet private weak var mapView: MKMapView!
    @IBOutlet private weak var locationStatusLabel: UILabel!
    @IBOutlet private weak var placeNameField: UITextField!
    @IBOutlet private weak var locatingIndicator: UIActivityIndicatorView!
    @IBOutlet private weak var saveBarButton: UIBarButtonItem!

    // MARK: State

    private let store: ListenStoring = ListenStore.shared
    private let locationService = LocationService()
    private var coordinate: Coordinate?   // nil until we know where the user is

    override func viewDidLoad() {
        super.viewDidLoad()
        artworkImageView.layer.cornerRadius = 12
        artworkImageView.clipsToBounds = true
        mapView.layer.cornerRadius = 12
        placeNameField.delegate = self
        saveBarButton.isEnabled = false

        guard let song = song else {
            songTitleLabel.text = "No song selected"
            return
        }
        songTitleLabel.text = song.title
        artistLabel.text = song.artist
        artworkImageView.image = UIImage(systemName: "music.note")
        ImageLoader.shared.loadImage(from: song.artworkURL(size: 300)) { [weak self] image in
            if let image = image { self?.artworkImageView.image = image }
        }

        locateUser()
    }

    // MARK: Location

    private func locateUser() {
        locatingIndicator.startAnimating()
        locationStatusLabel.text = "Finding where you are…"

        locationService.requestCurrentLocation { [weak self] result in
            guard let self = self else { return }
            self.locatingIndicator.stopAnimating()

            switch result {
            case .success(let location):
                self.use(Coordinate(location.coordinate), source: .gps)
                self.suggestName(for: location)
            case .failure(let error):
                if let fallback = self.fallbackCoordinate {
                    self.use(fallback, source: .mapCenter)
                    self.locationStatusLabel.text = "\(LocationSource.mapCenter.description)\n\(error.localizedDescription)"
                } else {
                    self.locationStatusLabel.text = error.localizedDescription
                }
            }
        }
    }

    private func use(_ coordinate: Coordinate, source: LocationSource) {
        self.coordinate = coordinate
        var source = source

        // If you're near a spot you've already saved, the listen joins that spot's playlist.
        if let existing = store.nearestPlace(to: coordinate) {
            source = .existingPlace(existing)
            placeNameField.text = existing.name
            placeNameField.isEnabled = false
        }
        locationStatusLabel.text = source.description

        let pin = MKPointAnnotation()
        pin.coordinate = coordinate.clCoordinate
        pin.title = song?.title
        mapView.removeAnnotations(mapView.annotations)
        mapView.addAnnotation(pin)
        mapView.setRegion(MKCoordinateRegion(center: coordinate.clCoordinate,
                                             latitudinalMeters: 800, longitudinalMeters: 800), animated: false)
        updateSaveButton()
    }

    private func suggestName(for location: CLLocation) {
        guard placeNameField.isEnabled, (placeNameField.text ?? "").isEmpty else { return }
        locationService.placeName(for: location) { [weak self] name in
            guard let self = self, let name = name, (self.placeNameField.text ?? "").isEmpty else { return }
            self.placeNameField.text = name
            self.updateSaveButton()
        }
    }

    private func updateSaveButton() {
        let hasName = !(placeNameField.text ?? "").trimmingCharacters(in: .whitespaces).isEmpty
        saveBarButton.isEnabled = coordinate != nil && hasName
    }

    // MARK: Actions

    @IBAction private func placeNameChanged(_ sender: UITextField) {
        updateSaveButton()
    }

    @IBAction private func saveTapped(_ sender: UIBarButtonItem) {
        guard let song = song, let coordinate = coordinate else { return }
        delegate?.logListen(self, didLog: song, at: coordinate, placeName: placeNameField.text ?? "")
    }
}

extension ConfirmListenViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
