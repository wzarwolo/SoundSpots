//
//  Song.swift
//  SoundSpots
//
//  Codable models for the iTunes Search API (https://itunes.apple.com/search).
//

import Foundation

/// Top-level JSON: { "resultCount": 25, "results": [ ... ] }
struct ITunesSearchResponse: Codable {
    let resultCount: Int
    let results: [ITunesTrack]
}

/// Raw track as returned by the API. Everything is optional because iTunes
/// sometimes leaves fields out, and one missing key shouldn't fail the whole response.
struct ITunesTrack: Codable {
    let trackId: Int?
    let trackName: String?
    let artistName: String?
    let collectionName: String?
    let artworkUrl100: String?
    let previewUrl: String?
    let primaryGenreName: String?
    let trackTimeMillis: Int?

    /// Failable conversion: returns nil when the essentials are missing.
    func toSong() -> Song? {
        guard let id = trackId, let name = trackName, let artist = artistName else { return nil }
        return Song(id: id,
                    title: name,
                    artist: artist,
                    album: collectionName,
                    artworkURLString: artworkUrl100,
                    previewURLString: previewUrl,
                    genre: primaryGenreName,
                    durationMillis: trackTimeMillis)
    }
}

/// The app's own clean song model. This is what gets saved to UserDefaults.
struct Song: Codable, Hashable {
    let id: Int
    let title: String
    let artist: String
    let album: String?
    let artworkURLString: String?
    let previewURLString: String?
    let genre: String?
    let durationMillis: Int?
}

extension Song {
    /// iTunes gives 100x100 artwork, but the same URL serves bigger sizes if we ask.
    func artworkURL(size: Int = 100) -> URL? {
        guard let urlString = artworkURLString else { return nil }
        return URL(string: urlString.replacingOccurrences(of: "100x100bb", with: "\(size)x\(size)bb"))
    }

    var previewURL: URL? {
        previewURLString.flatMap { URL(string: $0) }
    }

    /// e.g. "3:20"
    var durationText: String? {
        guard let millis = durationMillis else { return nil }
        let totalSeconds = millis / 1000
        return String(format: "%d:%02d", totalSeconds / 60, totalSeconds % 60)
    }

    var detailText: String {
        [album, genre, durationText].compactMap { $0 }.joined(separator: " • ")
    }
}
