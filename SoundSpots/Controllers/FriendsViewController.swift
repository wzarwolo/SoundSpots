//
//  FriendsViewController.swift
//  SoundSpots
//
//  Tab 4: where your friends are listening right now, on a map and in a list.
//

import UIKit
import MapKit

final class FriendsViewController: UIViewController {

    @IBOutlet private weak var mapView: MKMapView!
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!

    /// The screen only knows the protocol, so a real networked service can replace the simulated one.
    var friendsService: FriendsProviding = SimulatedFriendsService()

    private var friends: [Friend] = []
    private let cellID = "FriendCell"
    private let annotationReuseID = "FriendPin"
    private var settingsObserver: NSObjectProtocol?
    private let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter
    }()

    deinit {
        if let observer = settingsObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        mapView.delegate = self
        mapView.layer.cornerRadius = 16
        mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: annotationReuseID)
        SettingsStore.shared.settings.mapStyle.apply(to: mapView)

        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "person.badge.plus"),
                                                            primaryAction: UIAction { [weak self] _ in
                                                                self?.addFriendTapped()
                                                            })

        let refresh = UIRefreshControl()
        refresh.addTarget(self, action: #selector(refreshPulled(_:)), for: .valueChanged)
        tableView.refreshControl = refresh

        settingsObserver = NotificationCenter.default.addObserver(forName: .settingsDidChange, object: nil,
                                                                  queue: .main) { [weak self] _ in
            guard let mapView = self?.mapView else { return }
            SettingsStore.shared.settings.mapStyle.apply(to: mapView)
        }
        loadFriends()
    }

    private func loadFriends(completion: (() -> Void)? = nil) {
        if friends.isEmpty { activityIndicator.startAnimating() }
        // Escaping completion: called after the (simulated) network request finishes.
        friendsService.fetchFriends { [weak self] result in
            guard let self = self else { return }
            self.activityIndicator.stopAnimating()
            switch result {
            case .success(let friends):
                self.friends = friends.sorted { $0.lastActive > $1.lastActive }
                self.tableView.reloadData()
                self.showFriendsOnMap()
            case .failure(let error):
                self.showMessage(title: "Couldn't load friends", message: error.localizedDescription)
            }
            completion?()
        }
    }

    private func showFriendsOnMap() {
        mapView.removeAnnotations(mapView.annotations)
        let annotations = friends.map { FriendAnnotation(friend: $0) }
        mapView.addAnnotations(annotations)
        mapView.showAnnotations(annotations, animated: false)
    }

    @objc private func refreshPulled(_ sender: UIRefreshControl) {
        loadFriends { sender.endRefreshing() }
    }

    private func addFriendTapped() {
        showMessage(title: "Adding friends is coming soon",
                    message: "Real friends need accounts and a server. For now SoundSpots shows demo friends so you can see how it will work.")
    }
}

// MARK: - Table

extension FriendsViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        friends.isEmpty ? nil : "Listening now"
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        friends.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath)
        let friend = friends[indexPath.row]
        var content = UIListContentConfiguration.subtitleCell()
        content.text = "\(friend.emoji)  \(friend.name)"
        content.textProperties.font = .preferredFont(forTextStyle: .headline)
        content.secondaryText = "🎧 \(friend.nowPlaying.title) — \(friend.nowPlaying.artist)\n📍 \(friend.placeName) • \(relativeFormatter.localizedString(for: friend.lastActive, relativeTo: Date()))"
        content.secondaryTextProperties.color = .secondaryLabel
        content.secondaryTextProperties.numberOfLines = 2
        cell.contentConfiguration = content
        return cell
    }

    /// Tapping a friend zooms the map to them.
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let friend = friends[indexPath.row]
        mapView.setRegion(MKCoordinateRegion(center: friend.coordinate.clCoordinate,
                                             latitudinalMeters: 1_500, longitudinalMeters: 1_500), animated: true)
        if let pin = mapView.annotations.compactMap({ $0 as? FriendAnnotation }).first(where: { $0.friend.id == friend.id }) {
            mapView.selectAnnotation(pin, animated: true)
        }
    }
}

// MARK: - Map

extension FriendsViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let friendAnnotation = annotation as? FriendAnnotation else { return nil }
        let view = mapView.dequeueReusableAnnotationView(withIdentifier: annotationReuseID, for: friendAnnotation)
        guard let marker = view as? MKMarkerAnnotationView else { return view }
        marker.canShowCallout = true
        marker.markerTintColor = FriendAnnotation.tint
        marker.glyphText = friendAnnotation.friend.emoji
        return marker
    }
}
