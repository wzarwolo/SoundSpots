//
//  Library.swift
//  SoundSpots
//
//  Models for the features built on top of listening history:
//  custom playlists, the per-song memory box, and friends.
//

import Foundation

/// A playlist the user builds by hand (as opposed to the automatic "Mix" for each spot).
struct CustomPlaylist: Codable, Hashable {
    let id: UUID
    var name: String
    var songs: [Song]
    let dateCreated: Date

    init(id: UUID = UUID(), name: String, songs: [Song], dateCreated: Date = Date()) {
        self.id = id
        self.name = name
        self.songs = songs
        self.dateCreated = dateCreated
    }

    /// Total length of the playlist, if the songs report their duration.
    var durationText: String {
        let millis = songs.compactMap { $0.durationMillis }.reduce(0, +)
        let minutes = millis / 60_000
        return minutes > 0 ? "\(minutes) min" : ""
    }
}

/// Something saved in a song's memory box: a note, a photo, or both.
struct Memory: Codable, Hashable {
    let id: UUID
    let songID: Int
    var text: String?
    /// File name of a JPEG in the app's Documents/Memories folder (see PhotoStore).
    var imageFileName: String?
    let placeID: UUID?
    let date: Date

    init(id: UUID = UUID(), songID: Int, text: String? = nil, imageFileName: String? = nil,
         placeID: UUID? = nil, date: Date = Date()) {
        self.id = id
        self.songID = songID
        self.text = text
        self.imageFileName = imageFileName
        self.placeID = placeID
        self.date = date
    }

    var hasPhoto: Bool { imageFileName != nil }
}

/// A friend and what they're listening to right now. Friends are simulated (see FriendsService).
struct Friend: Codable, Hashable {
    let id: UUID
    let name: String
    let emoji: String
    let nowPlaying: Song
    let placeName: String
    let coordinate: Coordinate
    let lastActive: Date

    init(id: UUID = UUID(), name: String, emoji: String, nowPlaying: Song,
         placeName: String, coordinate: Coordinate, lastActive: Date) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.nowPlaying = nowPlaying
        self.placeName = placeName
        self.coordinate = coordinate
        self.lastActive = lastActive
    }
}

// MARK: - Backward-compatible decoding

/// Older saves only have `places` and `listens`. Decoding the new keys with `decodeIfPresent`
/// means existing users keep their history after updating the app.
/// (Defined in an extension so Swift still generates the memberwise initializer.)
extension ListeningHistory {
    private enum CodingKeys: String, CodingKey {
        case places, listens, customPlaylists, memories
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        places = try container.decodeIfPresent([Place].self, forKey: .places) ?? []
        listens = try container.decodeIfPresent([ListenEvent].self, forKey: .listens) ?? []
        customPlaylists = try container.decodeIfPresent([CustomPlaylist].self, forKey: .customPlaylists) ?? []
        memories = try container.decodeIfPresent([Memory].self, forKey: .memories) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(places, forKey: .places)
        try container.encode(listens, forKey: .listens)
        try container.encode(customPlaylists, forKey: .customPlaylists)
        try container.encode(memories, forKey: .memories)
    }
}

// MARK: - Formatting

/// "1 play", "2 plays". Keeps counts grammatical everywhere they're shown.
func pluralized(_ count: Int, _ singular: String, _ plural: String? = nil) -> String {
    "\(count) \(count == 1 ? singular : (plural ?? singular + "s"))"
}
