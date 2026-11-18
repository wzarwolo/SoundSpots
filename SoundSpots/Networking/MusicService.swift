//
//  MusicService.swift
//  SoundSpots
//
//  URLSession networking with @escaping completion handlers.
//

import Foundation

/// Anything that can search for songs. The real API client and the offline mock both conform,
/// so view controllers don't care which one they're given.
protocol MusicSearching {
    func searchSongs(matching term: String, completion: @escaping (Result<[Song], NetworkError>) -> Void)
}

/// Talks to Apple's public iTunes Search API (no API key needed).
final class ITunesMusicService: MusicSearching {

    private let session: URLSession
    private let resultLimit = 25

    /// Short timeout so the user isn't stuck on a spinner when offline.
    private static let defaultSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        return URLSession(configuration: config)
    }()

    init(session: URLSession = ITunesMusicService.defaultSession) {
        self.session = session
    }

    func searchSongs(matching term: String, completion: @escaping (Result<[Song], NetworkError>) -> Void) {
        var components = URLComponents(string: "https://itunes.apple.com/search")
        components?.queryItems = [
            URLQueryItem(name: "term", value: term),
            URLQueryItem(name: "media", value: "music"),
            URLQueryItem(name: "entity", value: "song"),
            URLQueryItem(name: "limit", value: String(resultLimit))
        ]

        // Always call back on the main thread so callers can update the UI directly.
        let finish: (Result<[Song], NetworkError>) -> Void = { result in
            DispatchQueue.main.async { completion(result) }
        }

        guard let url = components?.url else {
            finish(.failure(.invalidURL))
            return
        }

        // The closure below escapes: it runs after searchSongs has already returned.
        let task = session.dataTask(with: url) { data, response, error in
            if let error = error {
                finish(.failure(.requestFailed(error)))
                return
            }
            // Typecasting: URLResponse -> HTTPURLResponse to read the status code.
            if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                finish(.failure(.badStatusCode(http.statusCode)))
                return
            }
            guard let data = data else {
                finish(.failure(.noData))
                return
            }
            do {
                let decoded = try JSONDecoder().decode(ITunesSearchResponse.self, from: data)
                // compactMap drops any track that's missing essential fields.
                finish(.success(decoded.results.compactMap { $0.toSong() }))
            } catch {
                finish(.failure(.decodingFailed(error)))
            }
        }
        task.resume()
    }
}

/// Offline fallback with hand-written data (it's okay to mock some data).
final class MockMusicService: MusicSearching {

    func searchSongs(matching term: String, completion: @escaping (Result<[Song], NetworkError>) -> Void) {
        let matches = SampleData.songs.filter {
            $0.title.localizedCaseInsensitiveContains(term) || $0.artist.localizedCaseInsensitiveContains(term)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            completion(.success(matches.isEmpty ? SampleData.songs : matches))
        }
    }
}
