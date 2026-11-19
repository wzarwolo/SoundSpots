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

    // Custom playlists, memories, and spot customization
    var customPlaylists: [CustomPlaylist] { get }
    func savePlaylist(_ playlist: CustomPlaylist)
    func deletePlaylist(_ playlist: CustomPlaylist)
    func memories(for song: Song) -> [Memory]
    func addMemory(_ memory: Memory)
    func deleteMemory(_ memory: Memory)
    func updatePlace(_ place: Place)
}

/// One row of a "most listened" ranking.
struct RankedItem<Item> {
    let item: Item
    let plays: Int
}

/// Totals for the Stats tab.
struct YearSummary {
    let year: Int
    let listens: Int
    let minutes: Int
    let uniqueSongs: Int
    let spots: Int
    /// Listens per month, January first (12 values).
    let monthlyListens: [Int]
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
    var customPlaylists: [CustomPlaylist] { history.customPlaylists }
    var memories: [Memory] { history.memories }

    /// Songs without a duration count as this long when adding up listening time.
    private static let fallbackSongMillis = 210_000

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
        // Photos belong to memories; delete the files of any memory that's going away.
        let keptIDs = Set(newHistory.memories.map { $0.id })
        history.memories
            .filter { !keptIDs.contains($0.id) }
            .compactMap { $0.imageFileName }
            .forEach { PhotoStore.shared.deleteImage(named: $0) }
        history = newHistory
        persist()
    }

    /// Saves a renamed / re-iconed spot or its reminder settings.
    func updatePlace(_ place: Place) {
        guard let index = history.places.firstIndex(where: { $0.id == place.id }) else { return }
        history.places[index] = place
        persist()
    }

    // MARK: Custom playlists

    /// Inserts a new playlist or replaces an existing one with the same id.
    func savePlaylist(_ playlist: CustomPlaylist) {
        if let index = history.customPlaylists.firstIndex(where: { $0.id == playlist.id }) {
            history.customPlaylists[index] = playlist
        } else {
            history.customPlaylists.insert(playlist, at: 0)
        }
        persist()
    }

    func deletePlaylist(_ playlist: CustomPlaylist) {
        history.customPlaylists.removeAll { $0.id == playlist.id }
        persist()
    }

    func playlist(withID id: UUID) -> CustomPlaylist? {
        customPlaylists.first { $0.id == id }
    }

    // MARK: Memory box

    /// Newest first.
    func memories(for song: Song) -> [Memory] {
        memories.filter { $0.songID == song.id }.sorted { $0.date > $1.date }
    }

    func addMemory(_ memory: Memory) {
        history.memories.append(memory)
        persist()
    }

    func deleteMemory(_ memory: Memory) {
        if let fileName = memory.imageFileName {
            PhotoStore.shared.deleteImage(named: fileName)
        }
        history.memories.removeAll { $0.id == memory.id }
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

    /// Every song the user has logged, once each, newest first.
    func allSongs() -> [Song] {
        firstListens().map { $0.song }
    }

    /// The song first heard at this place longest ago (used in memory reminders).
    func oldestFirstListen(at place: Place) -> ListenEvent? {
        firstListens().filter { $0.placeID == place.id }.min { $0.date < $1.date }
    }

    // MARK: Stats

    func listens(inYear year: Int, calendar: Calendar = .current) -> [ListenEvent] {
        listens.filter { calendar.component(.year, from: $0.date) == year }
    }

    func yearSummary(for year: Int, calendar: Calendar = .current) -> YearSummary {
        let yearListens = listens(inYear: year, calendar: calendar)
        let millis = yearListens.reduce(0) { $0 + ($1.song.durationMillis ?? Self.fallbackSongMillis) }
        var monthly = Array(repeating: 0, count: 12)
        for listen in yearListens {
            monthly[calendar.component(.month, from: listen.date) - 1] += 1
        }
        return YearSummary(year: year,
                           listens: yearListens.count,
                           minutes: millis / 60_000,
                           uniqueSongs: Set(yearListens.map { $0.song.id }).count,
                           spots: Set(yearListens.map { $0.placeID }).count,
                           monthlyListens: monthly)
    }

    /// Places ranked by total plays, most first.
    func rankedPlaces() -> [RankedItem<Place>] {
        places
            .map { RankedItem(item: $0, plays: playCount(for: $0)) }
            .filter { $0.plays > 0 }
            .sorted { $0.plays > $1.plays }
    }

    /// Songs ranked by total plays across every spot, most first.
    func rankedSongs() -> [RankedItem<Song>] {
        Dictionary(grouping: listens) { $0.song.id }
            .values
            .compactMap { events -> RankedItem<Song>? in
                guard let song = events.first?.song else { return nil }
                return RankedItem(item: song, plays: events.count)
            }
            .sorted { $0.plays != $1.plays ? $0.plays > $1.plays : $0.item.title < $1.item.title }
    }

    private func persist() {
        defaults.setCodable(history, forKey: storageKey)
        NotificationCenter.default.post(name: .listeningHistoryDidChange, object: self)
    }
}
