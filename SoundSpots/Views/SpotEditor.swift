//
//  SpotEditor.swift
//  SoundSpots
//
//  One shared "Edit Spot" alert so spots can be renamed, given an emoji, and given a
//  custom memory message from the Playlists tab, a playlist, or Settings.
//

import UIKit

extension UIViewController {

    func presentSpotEditor(for place: Place, store: ListenStoring = ListenStore.shared,
                           completion: ((Place) -> Void)? = nil) {
        let alert = UIAlertController(title: "Edit Spot",
                                      message: "Rename it, give it an emoji, and write the memory message you'll get when you come back.",
                                      preferredStyle: .alert)
        alert.addTextField { field in
            field.placeholder = "Name"
            field.text = place.name
            field.autocapitalizationType = .words
            field.clearButtonMode = .whileEditing
        }
        alert.addTextField { field in
            field.placeholder = "Emoji (optional), e.g. 🏋️"
            field.text = place.emoji
        }
        alert.addTextField { field in
            field.placeholder = "Memory message (optional)"
            field.text = place.reminderNote
            field.autocapitalizationType = .sentences
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak alert] _ in
            guard let fields = alert?.textFields, fields.count == 3 else { return }
            var updated = place
            let name = fields[0].text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !name.isEmpty { updated.name = name }
            // Keep only the first emoji/character so the icon stays small.
            let emoji = fields[1].text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            updated.emoji = emoji.isEmpty ? nil : String(emoji.prefix(1))
            let note = fields[2].text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            updated.reminderNote = note.isEmpty ? nil : note
            store.updatePlace(updated)
            completion?(updated)
        })
        present(alert, animated: true)
    }

    /// Simple "OK" message.
    func showMessage(title: String, message: String?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
