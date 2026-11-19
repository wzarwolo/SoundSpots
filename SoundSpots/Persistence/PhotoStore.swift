//
//  PhotoStore.swift
//  SoundSpots
//
//  Memory photos are too big for UserDefaults, so they're saved as JPEG files in
//  Documents/Memories. The Memory struct only stores the file name.
//

import UIKit

final class PhotoStore {

    static let shared = PhotoStore()

    private let fileManager = FileManager.default
    private let cache = NSCache<NSString, UIImage>()

    private var folderURL: URL {
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let folder = documents.appendingPathComponent("Memories", isDirectory: true)
        if !fileManager.fileExists(atPath: folder.path) {
            try? fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
        }
        return folder
    }

    /// Saves a photo and returns its file name, or nil if it couldn't be written.
    func save(_ image: UIImage) -> String? {
        let resized = image.resizedToFit(maxDimension: 1600)
        guard let data = resized.jpegData(compressionQuality: 0.8) else { return nil }
        let fileName = UUID().uuidString + ".jpg"
        do {
            try data.write(to: folderURL.appendingPathComponent(fileName), options: .atomic)
            cache.setObject(resized, forKey: fileName as NSString)
            return fileName
        } catch {
            print("Couldn't save photo:", error)
            return nil
        }
    }

    func image(named fileName: String) -> UIImage? {
        if let cached = cache.object(forKey: fileName as NSString) { return cached }
        guard let image = UIImage(contentsOfFile: folderURL.appendingPathComponent(fileName).path) else { return nil }
        cache.setObject(image, forKey: fileName as NSString)
        return image
    }

    func deleteImage(named fileName: String) {
        cache.removeObject(forKey: fileName as NSString)
        try? fileManager.removeItem(at: folderURL.appendingPathComponent(fileName))
    }
}

private extension UIImage {
    /// Scales the image down so its longest side is at most `maxDimension` points.
    func resizedToFit(maxDimension: CGFloat) -> UIImage {
        let longest = max(size.width, size.height)
        guard longest > maxDimension else { return self }
        let scale = maxDimension / longest
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        return UIGraphicsImageRenderer(size: newSize, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
