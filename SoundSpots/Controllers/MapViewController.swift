//
//  MapViewController.swift
//  SoundSpots
//
//  Tab 1: every place you've listened to music, as pins on a map.
//

import UIKit
import MapKit

final class MapViewController: UIViewController {

    @IBOutlet private weak var mapView: MKMapView!
    @IBOutlet private weak var hintContainer: UIView!
    @IBOutlet private weak var hintLabel: UILabel!

    private let store = ListenStore.shared
    private var historyObserver: NSObjectProtocol?
    private let annotationReuseID = "PlacePin"

    /// Used when there's no data yet (downtown San Francisco).
    private let defaultRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7650, longitude: -122.4450),
        latitudinalMeters: 12_000, longitudinalMeters: 12_000)

    deinit {
        if let observer = historyObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: annotationReuseID)
        mapView.setRegion(defaultRegion, animated: false)

        hintContainer.layer.cornerRadius = 14
        hintContainer.layer.shadowColor = UIColor.black.cgColor
        hintContainer.layer.shadowOpacity = 0.15
        hintContainer.layer.shadowRadius = 8
        hintContainer.layer.shadowOffset = CGSize(width: 0, height: 2)

        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Options",
                                                           image: UIImage(systemName: "ellipsis.circle"),
                                                           menu: makeOptionsMenu())

        historyObserver = NotificationCenter.default.addObserver(forName: .listeningHistoryDidChange,
                                                                 object: nil, queue: .main) { [weak self] _ in
            // If the map was empty before (e.g. demo data just loaded), zoom to show the new pins.
            let wasEmpty = self?.mapView.annotations.contains { $0 is PlaceAnnotation } == false
            self?.reloadAnnotations(zoomToFit: wasEmpty)
        }
        reloadAnnotations(zoomToFit: true)
    }

    // MARK: Map content

    private func reloadAnnotations(zoomToFit: Bool) {
        mapView.removeAnnotations(mapView.annotations.filter { $0 is PlaceAnnotation })

        let annotations = store.places.map {
            PlaceAnnotation(place: $0, playCount: store.playCount(for: $0), topSong: store.topSong(at: $0))
        }
        mapView.addAnnotations(annotations)

        let listenCount = store.listens.count
        if annotations.isEmpty {
            hintLabel.text = "Tap ＋ to log the song you're listening to right now. It will be pinned here."
        } else {
            hintLabel.text = "🎧 \(listenCount) listens across \(annotations.count) spots. Tap a pin for its playlist."
        }

        if zoomToFit && !annotations.isEmpty {
            // Leave room for the hint card at the bottom and the bars at the top.
            mapView.layoutIfNeeded()
            let rect = annotations.reduce(MKMapRect.null) { rect, annotation in
                rect.union(MKMapRect(origin: MKMapPoint(annotation.coordinate), size: MKMapSize(width: 1, height: 1)))
            }
            mapView.setVisibleMapRect(rect,
                                      edgePadding: UIEdgeInsets(top: 160, left: 60, bottom: 220, right: 60),
                                      animated: false)
        }
    }

    private func focus(on place: Place) {
        let region = MKCoordinateRegion(center: place.coordinate.clCoordinate,
                                        latitudinalMeters: 2_000, longitudinalMeters: 2_000)
        mapView.setRegion(region, animated: true)
        // Typecast each annotation to find the one for this place.
        let match = mapView.annotations
            .compactMap { $0 as? PlaceAnnotation }
            .first { $0.place.id == place.id }
        if let match = match {
            mapView.selectAnnotation(match, animated: true)
        }
    }

    private func makeOptionsMenu() -> UIMenu {
        let showAll = UIAction(title: "Show All Spots", image: UIImage(systemName: "map")) { [weak self] _ in
            guard let self = self else { return }
            self.mapView.showAnnotations(self.mapView.annotations, animated: true)
        }
        let loadDemo = UIAction(title: "Load Demo Data", image: UIImage(systemName: "sparkles")) { [weak self] _ in
            self?.store.replaceAll(with: SampleData.makeHistory())
            self?.reloadAnnotations(zoomToFit: true)
        }
        let clear = UIAction(title: "Clear All Data", image: UIImage(systemName: "trash"),
                             attributes: .destructive) { [weak self] _ in
            self?.confirmClearAll()
        }
        return UIMenu(children: [showAll, loadDemo, clear])
    }

    private func confirmClearAll() {
        let alert = UIAlertController(title: "Clear all listening history?",
                                      message: "Every spot and playlist will be deleted. This can't be undone.",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Clear", style: .destructive) { [weak self] _ in
            self?.store.replaceAll(with: ListeningHistory())
        })
        present(alert, animated: true)
    }

    // MARK: Navigation (passing data forward)

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch SegueIdentifier(rawValue: segue.identifier ?? "") {
        case .showPlaylist:
            guard let playlistVC = segue.destination as? PlaylistViewController,
                  let place = sender as? Place else { return }
            playlistVC.place = place

        case .showLogListen:
            // The modal segue targets a navigation controller; typecast down to our screen.
            guard let navController = segue.destination as? UINavigationController,
                  let logVC = navController.topViewController as? LogListenViewController else { return }
            logVC.fallbackCoordinate = Coordinate(mapView.centerCoordinate)
            logVC.delegate = self

        default:
            break
        }
    }
}

// MARK: - MKMapViewDelegate

extension MapViewController: MKMapViewDelegate {

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        // Leave the blue "you are here" dot alone; only style our own pins.
        guard let placeAnnotation = annotation as? PlaceAnnotation else { return nil }

        let view = mapView.dequeueReusableAnnotationView(withIdentifier: annotationReuseID, for: placeAnnotation)
        guard let marker = view as? MKMarkerAnnotationView else { return view }

        marker.canShowCallout = true
        marker.markerTintColor = .brandPink
        marker.glyphImage = UIImage(systemName: "music.note")
        marker.displayPriority = .required
        marker.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        return marker
    }

    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView,
                 calloutAccessoryControlTapped control: UIControl) {
        guard let placeAnnotation = view.annotation as? PlaceAnnotation else { return }
        performSegue(withIdentifier: SegueIdentifier.showPlaylist.rawValue, sender: placeAnnotation.place)
    }
}

// MARK: - LogListenDelegate (data passed back from the modal flow)

extension MapViewController: LogListenDelegate {

    func logListen(_ controller: UIViewController, didLog song: Song, at coordinate: Coordinate, placeName: String) {
        let place = store.logListen(of: song, at: coordinate, placeName: placeName)
        controller.dismiss(animated: true) { [weak self] in
            self?.focus(on: place)
        }
    }

    func logListenDidCancel(_ controller: UIViewController) {
        controller.dismiss(animated: true)
    }
}
