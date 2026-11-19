//
//  Enums.swift
//  SoundSpots
//

import UIKit
import MapKit

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
    case showCreatePlaylist
    case showCustomPlaylist
    case showMemoryBox
    case showSettings
}

/// Light / dark mode choice. Raw values match the segmented control in Settings.
enum AppTheme: Int, Codable, CaseIterable {
    case system = 0
    case light
    case dark

    var title: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var interfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .system: return .unspecified
        case .light: return .light
        case .dark: return .dark
        }
    }
}

/// The app's accent color, picked in Settings.
enum AccentChoice: String, Codable, CaseIterable {
    case pink, purple, blue, teal, orange

    var title: String { rawValue.capitalized }

    var color: UIColor {
        switch self {
        case .pink: return UIColor(red: 0.98, green: 0.20, blue: 0.40, alpha: 1)
        case .purple: return .systemPurple
        case .blue: return .systemBlue
        case .teal: return .systemTeal
        case .orange: return .systemOrange
        }
    }
}

/// Map layouts the user can switch between.
enum MapStyle: Int, Codable, CaseIterable {
    case standard = 0
    case muted
    case satellite
    case hybrid

    var title: String {
        switch self {
        case .standard: return "Standard"
        case .muted: return "Muted"
        case .satellite: return "Satellite"
        case .hybrid: return "Hybrid"
        }
    }

    var symbolName: String {
        switch self {
        case .standard: return "map"
        case .muted: return "map.circle"
        case .satellite: return "globe.americas"
        case .hybrid: return "square.2.layers.3d"
        }
    }

    func apply(to mapView: MKMapView) {
        switch self {
        case .standard:
            mapView.preferredConfiguration = MKStandardMapConfiguration(emphasisStyle: .default)
        case .muted:
            mapView.preferredConfiguration = MKStandardMapConfiguration(emphasisStyle: .muted)
        case .satellite:
            mapView.preferredConfiguration = MKImageryMapConfiguration()
        case .hybrid:
            mapView.preferredConfiguration = MKHybridMapConfiguration()
        }
    }
}

/// Tier-list ranks, best first.
enum Tier: String, CaseIterable {
    case s = "S", a = "A", b = "B", c = "C", d = "D"

    var color: UIColor {
        switch self {
        case .s: return .systemRed
        case .a: return .systemOrange
        case .b: return .systemYellow
        case .c: return .systemGreen
        case .d: return .systemBlue
        }
    }

    var symbolName: String { "\(rawValue.lowercased()).square.fill" }

    /// Share of the ranked list that lands in each tier (adds up to 1).
    private var share: Double {
        switch self {
        case .s: return 0.10
        case .a: return 0.20
        case .b: return 0.30
        case .c: return 0.25
        case .d: return 0.15
        }
    }

    /// Splits an already-ranked list (best first) into tiers. Generic, so it works for
    /// songs and places alike. Empty tiers are left out.
    static func assign<Item>(_ ranked: [Item]) -> [(tier: Tier, items: [Item])] {
        guard !ranked.isEmpty else { return [] }
        var result: [(tier: Tier, items: [Item])] = []
        var start = 0
        var cumulative = 0.0
        for tier in allCases {
            cumulative += tier.share
            // S always gets at least one item; the last tier takes whatever is left.
            var end = tier == .d ? ranked.count : Int((Double(ranked.count) * cumulative).rounded())
            if tier == .s { end = max(end, 1) }
            end = min(max(end, start), ranked.count)
            if end > start {
                result.append((tier, Array(ranked[start..<end])))
            }
            start = end
        }
        return result
    }
}

/// What the Stats tab's tier list ranks.
enum TierListMode: Int, CaseIterable {
    case songs = 0
    case places

    var title: String { self == .songs ? "Songs" : "Spots" }
}
