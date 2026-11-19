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
    private let settingsStore = SettingsStore.shared
    private var historyObserver: NSObjectProtocol?
    private var settingsObserver: NSObjectProtocol?
    private let annotationReuseID = "PlacePin"
    private let friendReuseID = "FriendPin"
    private let friendsService: FriendsProviding = SimulatedFriendsService()
    private let photoCapture = PhotoCapture()

    /// Used when there's no data yet (downtown San Francisco).
    private let defaultRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7650, longitude: -122.4450),
        latitudinalMeters: 12_000, longitudinalMeters: 12_000)

    deinit {
        [historyObserver, settingsObserver].compactMap { $0 }.forEach {
            NotificationCenter.default.removeObserver($0)
        }
    }

    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: annotationReuseID)
        mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: friendReuseID)
        mapView.setRegion(defaultRegion, animated: false)
        settingsStore.settings.mapStyle.apply(to: mapView)

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
        settingsObserver = NotificationCenter.default.addObserver(forName: .settingsDidChange,
                                                                  object: nil, queue: .main) { [weak self] _ in
            self?.applySettings()
        }
        reloadAnnotations(zoomToFit: true)
        reloadFriends()
    }

    // MARK: Settings

    private func applySettings() {
        settingsStore.settings.mapStyle.apply(to: mapView)
        // Rebuild the menu so the checkmark moves to the current map style.
        navigationItem.leftBarButtonItem?.menu = makeOptionsMenu()
        reloadFriends()
        // Re-tint pins in case the accent color changed.
        reloadAnnotations(zoomToFit: false)
    }

    /// Shows or hides friends' pins, depending on the setting.
    private func reloadFriends() {
        mapView.removeAnnotations(mapView.annotations.filter { $0 is FriendAnnotation })
        guard settingsStore.settings.showFriendsOnMap else { return }
        friendsService.fetchFriends { [weak self] result in
            guard let self = self, self.settingsStore.settings.showFriendsOnMap,
                  case .success(let friends) = result else { return }
            self.mapView.removeAnnotations(self.mapView.annotations.filter { $0 is FriendAnnotation })
            self.mapView.addAnnotations(friends.map { FriendAnnotation(friend: $0) })
        }
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
        let styles = MapStyle.allCases.map { style in
            UIAction(title: style.title, image: UIImage(systemName: style.symbolName),
                     state: style == settingsStore.settings.mapStyle ? .on : .off) { [weak self] _ in
                self?.settingsStore.update { $0.mapStyle = style }
            }
        }
        let styleMenu = UIMenu(title: "Map Style", image: UIImage(systemName: "square.3.layers.3d"), children: styles)
        let friends = UIAction(title: "Show Friends", image: UIImage(systemName: "person.2"),
                               state: settingsStore.settings.showFriendsOnMap ? .on : .off) { [weak self] _ in
            self?.settingsStore.update { $0.showFriendsOnMap.toggle() }
        }
        let settings = UIAction(title: "Settings", image: UIImage(systemName: "gearshape")) { [weak self] _ in
            self?.performSegue(withIdentifier: SegueIdentifier.showSettings.rawValue, sender: nil)
        }
        let viewSection = UIMenu(options: .displayInline, children: [showAll, styleMenu, friends])
        let loadDemo = UIAction(title: "Load Demo Data", image: UIImage(systemName: "sparkles")) { [weak self] _ in
            self?.store.replaceAll(with: SampleData.makeHistory())
            self?.reloadAnnotations(zoomToFit: true)
        }
        let clear = UIAction(title: "Clear All Data", image: UIImage(systemName: "trash"),
                             attributes: .destructive) { [weak self] _ in
            self?.confirmClearAll()
        }
        let dataSection = UIMenu(options: .displayInline, children: [loadDemo, clear])
        return UIMenu(children: [viewSection, dataSection, settings])
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
        // Friends get their own color and their emoji as the glyph.
        if let friendAnnotation = annotation as? FriendAnnotation {
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: friendReuseID, for: friendAnnotation)
            guard let marker = view as? MKMarkerAnnotationView else { return view }
            marker.canShowCallout = true
            marker.markerTintColor = FriendAnnotation.tint
            marker.glyphText = friendAnnotation.friend.emoji
            marker.displayPriority = .defaultHigh
            return marker
        }

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
        let isFirstListen = store.firstListen(of: song) == nil
        let place = store.logListen(of: song, at: coordinate, placeName: placeName)
        controller.dismiss(animated: true) { [weak self] in
            self?.focus(on: place)
            if isFirstListen {
                self?.offerFirstListenPhoto(for: song, at: place)
            }
        }
    }

    /// The first time a song is logged, offer to snap a photo to capture the moment.
    private func offerFirstListenPhoto(for song: Song, at place: Place) {
        let alert = UIAlertController(title: "📸 First listen!",
                                      message: "Capture the moment you first heard “\(song.title)” at \(place.displayName)? It goes in the song's Memory Box.",
                                      preferredStyle: .actionSheet)
        photoCapture.addActions(to: alert, presenter: self) { [weak self] image in
            guard let image = image, let fileName = PhotoStore.shared.save(image) else { return }
            self?.store.addMemory(Memory(songID: song.id, text: "First listen at \(place.name)",
                                         imageFileName: fileName, placeID: place.id))
            self?.showMessage(title: "Saved to the Memory Box", message: "Open “\(song.title)” and tap the box icon to see it.")
        }
        alert.addAction(UIAlertAction(title: "Not Now", style: .cancel))
        alert.popoverPresentationController?.sourceView = view
        present(alert, animated: true)
    }

    func logListenDidCancel(_ controller: UIViewController) {
        controller.dismiss(animated: true)
    }
}
