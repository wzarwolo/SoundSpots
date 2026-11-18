//
//  Enums.swift
//  SoundSpots
//

import Foundation

/// How a location's playlist is ordered. Raw values match the segmented control indexes.
enum PlaylistSort: Int, CaseIterable {
    case mostPlayed = 0
    case recent
    case firstHeardHere

    var title: String {
        switch self {
        case .mostPlayed: return "Most Played"
        case .recent: return "Recent"
        case .firstHeardHere: return "Firsts"
        }
    }

    func sorted(_ items: [PlaylistItem]) -> [PlaylistItem] {
        switch self {
        case .mostPlayed:
            return items.sorted {
                $0.playCount != $1.playCount ? $0.playCount > $1.playCount : $0.lastPlayed > $1.lastPlayed
            }
        case .recent:
            return items.sorted { $0.lastPlayed > $1.lastPlayed }
        case .firstHeardHere:
            return items.filter { $0.isFirstHeardHere }.sorted { $0.playCount > $1.playCount }
        }
    }
}

/// Where the coordinate for a new listen came from.
enum LocationSource {
    case gps
    case mapCenter
    case existingPlace(Place)   // associated value

    var description: String {
        switch self {
        case .gps: return "📍 Using your current location"
        case .mapCenter: return "🗺️ Location unavailable, using the map's center instead"
        case .existingPlace(let place): return "📌 Adding to “\(place.name)”"
        }
    }
}

/// Segue identifiers in one place instead of string literals scattered around.
enum SegueIdentifier: String {
    case showPlaylist
    case showSong
    case showLogListen
    case showConfirmListen
}
