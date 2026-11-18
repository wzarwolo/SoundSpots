//
//  ListenStore.swift
//  SoundSpots
//
//  Saves places + listens to UserDefaults with Codable, and answers questions about them
//  ("where did I first hear this?", "what do I play most at the gym?").
//

import Foundation

extension Notification.Name {
    /// Posted whenever the saved history changes, so every screen can refresh.
    static let listeningHistoryDidChange = Notification.Name("listeningHistoryDidChange")
}

/// What the rest of the app needs from storage. View controllers depend on this protocol,
/// not on the concrete class.
protocol ListenStoring: AnyObject {
    var places: [Place] { get }
    var listens: [ListenEvent] { get }

    @discardableResult
    func logListen(of song: Song, at coordinate: Coordinate, placeName: String) -> Place
    func place(withID id: UUID) -> Place?
    func nearestPlace(to coordinate: Coordinate) -> Place?
    func firstListen(of song: Song) -> ListenEvent?
    func playlist(for place: Place) -> [PlaylistItem]
    func playCount(for place: Place) -> Int
    func deletePlace(_ place: Place)
    func replaceAll(with history: ListeningHistory)
}

final class ListenStore: ListenStoring {

    static let shared = ListenStore()

    /// Listens within this many meters of an existing place are grouped into that place.
    static let samePlaceRadius: Double = 150

    private let defaults: UserDefaults
    private let storageKey = "listening.history.v1"
    private var history: ListeningHistory

    var places: [Place] { history.places }
    var listens: [ListenEvent] { history.listens }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        // Load saved data at launch. First launch has nothing saved, so fall back to empty.
        self.history = defaults.codable(ListeningHistory.self, forKey: storageKey) ?? ListeningHistory()
    }

    // MARK: Writing

    @discardableResult
    func logListen(of song: Song, at coordinate: Coordinate, placeName: String) -> Place {
        let place: Place
        if let existing = nearestPlace(to: coordinate) {
            place = existing
        } else {
            let trimmed = placeName.trimmingCharacters(in: .whitespacesAndNewlines)
            place = Place(name: trimmed.isEmpty ? "Unnamed Spot" : trimmed, coordinate: coordinate)
            history.places.append(place)
        }
        history.listens.append(ListenEvent(song: song, placeID: place.id))
        persist()
        return place
    }

    func deletePlace(_ place: Place) {
        history.places.removeAll { $0.id == place.id }
        history.listens.removeAll { $0.placeID == place.id }
        persist()
    }

    func replaceAll(with newHistory: ListeningHistory) {
        history = newHistory
        persist()
    }

    // MARK: Reading

    func place(withID id: UUID) -> Place? {
        places.first { $0.id == id }
    }

    func nearestPlace(to coordinate: Coordinate) -> Place? {
        places
            .map { (place: $0, distance: $0.coordinate.distance(to: coordinate)) }
            .filter { $0.distance <= Self.samePlaceRadius }
            .min { $0.distance < $1.distance }?
            .place
    }

    /// The earliest time the user logged this song, anywhere.
    func firstListen(of song: Song) -> ListenEvent? {
        listens.filter { $0.song.id == song.id }.min { $0.date < $1.date }
    }

    /// Every song ever played at a place, with how many times and when.
    func playlist(for place: Place) -> [PlaylistItem] {
        let listensHere = listens.filter { $0.placeID == place.id }
        let bySong = Dictionary(grouping: listensHere) { $0.song.id }

        return bySong.values.compactMap { events -> PlaylistItem? in
            guard let latest = events.max(by: { $0.date < $1.date }) else { return nil }
            let firstEver = firstListen(of: latest.song)
            return PlaylistItem(song: latest.song,
                                playCount: events.count,
                                lastPlayed: latest.date,
                                isFirstHeardHere: firstEver?.placeID == place.id)
        }
    }

    func playCount(for place: Place) -> Int {
        listens.filter { $0.placeID == place.id }.count
    }

    /// One entry per unique song: where and when it was first heard. Newest first.
    func firstListens() -> [ListenEvent] {
        let bySong = Dictionary(grouping: listens) { $0.song.id }
        return bySong.values
            .compactMap { $0.min { $0.date < $1.date } }
            .sorted { $0.date > $1.date }
    }

    func totalPlays(of song: Song) -> Int {
        listens.filter { $0.song.id == song.id }.count
    }

    /// The song played most at a place (used as the map pin subtitle).
    func topSong(at place: Place) -> Song? {
        PlaylistSort.mostPlayed.sorted(playlist(for: place)).first?.song
    }

    private func persist() {
        defaults.setCodable(history, forKey: storageKey)
        NotificationCenter.default.post(name: .listeningHistoryDidChange, object: self)
    }
}
