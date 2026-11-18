//
//  PlaceAnnotation.swift
//  SoundSpots
//

import MapKit

/// A map pin for a Place. Conforming to MapKit's `MKAnnotation` protocol is
/// what lets MKMapView display it.
final class PlaceAnnotation: NSObject, MKAnnotation {

    let place: Place
    let playCount: Int
    let topSong: Song?

    init(place: Place, playCount: Int, topSong: Song?) {
        self.place = place
        self.playCount = playCount
        self.topSong = topSong
    }

    var coordinate: CLLocationCoordinate2D { place.coordinate.clCoordinate }

    var title: String? { place.name }

    var subtitle: String? {
        guard let song = topSong else { return "\(playCount) plays" }
        return "🔥 \(song.title) • \(playCount) plays"
    }
}
