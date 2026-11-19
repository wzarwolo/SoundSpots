//
//  Place.swift
//  SoundSpots
//

import Foundation
import CoreLocation

/// CLLocationCoordinate2D isn't Codable, so we store our own simple struct.
struct Coordinate: Codable, Hashable {
    let latitude: Double
    let longitude: Double

    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }

    init(_ coordinate: CLLocationCoordinate2D) {
        self.init(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }

    var clCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    /// Distance in meters between two coordinates.
    func distance(to other: Coordinate) -> CLLocationDistance {
        CLLocation(latitude: latitude, longitude: longitude)
            .distance(from: CLLocation(latitude: other.latitude, longitude: other.longitude))
    }
}

/// A spot on the map where the user listens to music. Each place is also a playlist.
struct Place: Codable, Hashable {
    let id: UUID
    var name: String
    let coordinate: Coordinate
    let dateCreated: Date
    /// Optional customizations. Optionals decode as nil from older saves that don't have them.
    var emoji: String?
    var reminderNote: String?
    var remindersEnabled: Bool?

    init(id: UUID = UUID(), name: String, coordinate: Coordinate, dateCreated: Date = Date(),
         emoji: String? = nil, reminderNote: String? = nil, remindersEnabled: Bool? = nil) {
        self.id = id
        self.name = name
        self.coordinate = coordinate
        self.dateCreated = dateCreated
        self.emoji = emoji
        self.reminderNote = reminderNote
        self.remindersEnabled = remindersEnabled
    }

    /// The name with its emoji in front, e.g. "🏋️ The Gym".
    var displayName: String {
        guard let emoji = emoji, !emoji.isEmpty else { return name }
        return "\(emoji) \(name)"
    }

    /// Reminders are on unless the user turned them off for this spot.
    var wantsReminders: Bool { remindersEnabled ?? true }
}

/// One "I listened to this song here" event.
struct ListenEvent: Codable, Hashable {
    let id: UUID
    let song: Song
    let placeID: UUID
    let date: Date

    init(id: UUID = UUID(), song: Song, placeID: UUID, date: Date = Date()) {
        self.id = id
        self.song = song
        self.placeID = placeID
        self.date = date
    }
}

/// Everything we persist, wrapped in one Codable value.
struct ListeningHistory: Codable {
    var places: [Place] = []
    var listens: [ListenEvent] = []
    var customPlaylists: [CustomPlaylist] = []
    var memories: [Memory] = []
}

/// A row in a location-based playlist. Built on the fly, not saved.
struct PlaylistItem {
    let song: Song
    let playCount: Int
    let lastPlayed: Date
    let isFirstHeardHere: Bool
}
