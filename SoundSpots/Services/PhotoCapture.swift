//
//  PhotoCapture.swift
//  SoundSpots
//
//  Takes a photo with the camera or picks one from the library, then hands the image
//  back through an escaping closure. The simulator has no camera, so the camera option
//  only appears on a real iPhone.
//

import UIKit
import PhotosUI

final class PhotoCapture: NSObject {

    enum Source {
        case camera
        case library
    }

    static var isCameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    private var completion: ((UIImage?) -> Void)?

    /// Presents the picker. `completion` gets the image, or nil if the user cancelled.
    func present(from viewController: UIViewController, source: Source,
                 completion: @escaping (UIImage?) -> Void) {
        self.completion = completion

        switch source {
        case .camera where Self.isCameraAvailable:
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            viewController.present(picker, animated: true)

        default:
            var config = PHPickerConfiguration()
            config.filter = .images
            config.selectionLimit = 1
            let picker = PHPickerViewController(configuration: config)
            picker.delegate = self
            viewController.present(picker, animated: true)
        }
    }

    /// Adds "Take Photo" (when there's a camera) and "Choose Photo" actions to an alert or sheet.
    func addActions(to alert: UIAlertController, presenter: UIViewController,
                    completion: @escaping (UIImage?) -> Void) {
        if Self.isCameraAvailable {
            alert.addAction(UIAlertAction(title: "Take Photo", style: .default) { [weak self, weak presenter] _ in
                guard let presenter = presenter else { return }
                self?.present(from: presenter, source: .camera, completion: completion)
            })
        }
        alert.addAction(UIAlertAction(title: "Choose Photo", style: .default) { [weak self, weak presenter] _ in
            guard let presenter = presenter else { return }
            self?.present(from: presenter, source: .library, completion: completion)
        })
    }

    private func finish(with image: UIImage?) {
        let callback = completion
        completion = nil
        DispatchQueue.main.async { callback?(image) }
    }
}

extension PhotoCapture: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        let image = info[.originalImage] as? UIImage
        picker.dismiss(animated: true) { [weak self] in self?.finish(with: image) }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true) { [weak self] in self?.finish(with: nil) }
    }
}

extension PhotoCapture: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else {
            finish(with: nil)
            return
        }
        provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
            self?.finish(with: object as? UIImage)
        }
    }
}
