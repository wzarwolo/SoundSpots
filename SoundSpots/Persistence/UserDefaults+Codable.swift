//
//  UserDefaults+Codable.swift
//  SoundSpots
//

import Foundation

/// Generic helpers so any Codable type can be saved to / loaded from UserDefaults as JSON.
extension UserDefaults {

    func setCodable<T: Encodable>(_ value: T, forKey key: String) {
        do {
            let data = try JSONEncoder().encode(value)
            set(data, forKey: key)
        } catch {
            print("⚠️ Failed to encode \(T.self): \(error)")
        }
    }

    func codable<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = data(forKey: key) else { return nil }
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            print("⚠️ Failed to decode \(T.self): \(error)")
            return nil
        }
    }
}
