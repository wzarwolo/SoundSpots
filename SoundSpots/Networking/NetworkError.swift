//
//  NetworkError.swift
//  SoundSpots
//

import Foundation

/// Every way a request can fail, as an enum with associated values.
enum NetworkError: LocalizedError {
    case invalidURL
    case requestFailed(Error)
    case badStatusCode(Int)
    case noData
    case decodingFailed(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The search couldn't be built into a valid URL."
        case .requestFailed(let error):
            return "Couldn't reach iTunes: \(error.localizedDescription)"
        case .badStatusCode(let code):
            return "iTunes responded with status code \(code)."
        case .noData:
            return "iTunes returned no data."
        case .decodingFailed:
            return "The data from iTunes was in an unexpected format."
        }
    }
}
