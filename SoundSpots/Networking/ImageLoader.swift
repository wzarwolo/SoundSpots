//
//  ImageLoader.swift
//  SoundSpots
//

import UIKit

/// Downloads poster images with URLSession and caches them in memory.
final class ImageLoader {

    static let shared = ImageLoader()

    private let cache = NSCache<NSURL, UIImage>()
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    /// Returns the task so a reused table cell can cancel a download it no longer needs.
    @discardableResult
    func loadImage(from url: URL?, completion: @escaping (UIImage?) -> Void) -> URLSessionDataTask? {
        guard let url = url else {
            completion(nil)
            return nil
        }
        // Typecasting: bridge Swift's URL to NSURL, which NSCache requires as a key.
        if let cached = cache.object(forKey: url as NSURL) {
            completion(cached)
            return nil
        }

        let task = session.dataTask(with: url) { [weak self] data, _, _ in
            let image = data.flatMap { UIImage(data: $0) }
            if let image = image {
                self?.cache.setObject(image, forKey: url as NSURL)
            }
            DispatchQueue.main.async { completion(image) }
        }
        task.resume()
        return task
    }
}
