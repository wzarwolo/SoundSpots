//
//  FriendAnnotation.swift
//  SoundSpots
//

import MapKit

/// A friend's pin on the map. Styled differently from your own spots.
final class FriendAnnotation: NSObject, MKAnnotation {

    let friend: Friend

    init(friend: Friend) {
        self.friend = friend
    }

    var coordinate: CLLocationCoordinate2D { friend.coordinate.clCoordinate }
    var title: String? { "\(friend.emoji) \(friend.name)" }
    var subtitle: String? { "🎧 \(friend.nowPlaying.title) • \(friend.placeName)" }

    static let tint = UIColor.systemIndigo
}
