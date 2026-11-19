//
//  FriendsService.swift
//  SoundSpots
//
//  Where your friends are listening. A real version needs accounts and a server, so the
//  app talks to a protocol and ships with a simulated service. Swapping in a networked
//  service later doesn't change any screen.
//

import Foundation

protocol FriendsProviding {
    func fetchFriends(completion: @escaping (Result<[Friend], NetworkError>) -> Void)
}

/// Returns a fixed group of demo friends around San Francisco, after a short fake network delay.
final class SimulatedFriendsService: FriendsProviding {

    func fetchFriends(completion: @escaping (Result<[Friend], NetworkError>) -> Void) {
        let friends = Self.makeFriends(now: Date())
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            completion(.success(friends))
        }
    }

    private static func makeFriends(now: Date) -> [Friend] {
        let songs = SampleData.songs
        func song(_ index: Int) -> Song { songs[index % songs.count] }
        let minute: TimeInterval = 60

        return [
            Friend(name: "Maya", emoji: "🎸", nowPlaying: song(1), placeName: "Dolores Park",
                   coordinate: Coordinate(latitude: 37.7596, longitude: -122.4269),
                   lastActive: now.addingTimeInterval(-4 * minute)),
            Friend(name: "Jordan", emoji: "🏀", nowPlaying: song(9), placeName: "Golden Gate Park",
                   coordinate: Coordinate(latitude: 37.7694, longitude: -122.4862),
                   lastActive: now.addingTimeInterval(-12 * minute)),
            Friend(name: "Priya", emoji: "📚", nowPlaying: song(4), placeName: "Campus Library",
                   coordinate: Coordinate(latitude: 37.7223, longitude: -122.4789),
                   lastActive: now.addingTimeInterval(-27 * minute)),
            Friend(name: "Leo", emoji: "☕️", nowPlaying: song(6), placeName: "Hayes Valley",
                   coordinate: Coordinate(latitude: 37.7764, longitude: -122.4241),
                   lastActive: now.addingTimeInterval(-55 * minute)),
            Friend(name: "Sam", emoji: "🌊", nowPlaying: song(8), placeName: "Ocean Beach",
                   coordinate: Coordinate(latitude: 37.7603, longitude: -122.5095),
                   lastActive: now.addingTimeInterval(-3 * 60 * minute))
        ]
    }
}
