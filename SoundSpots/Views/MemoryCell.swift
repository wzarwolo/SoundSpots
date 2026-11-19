//
//  MemoryCell.swift
//  SoundSpots
//
//  A memory box entry: an optional photo, an optional note, and when/where it was saved.
//  Laid out with Auto Layout in code because its photo shows or hides per row.
//

import UIKit

final class MemoryCell: UITableViewCell, ReuseIdentifiable {

    private let photoView = UIImageView()
    private let noteLabel = UILabel()
    private let metaLabel = UILabel()
    private let stack = UIStackView()
    private var photoHeight: NSLayoutConstraint!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setUp()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setUp()
    }

    private func setUp() {
        selectionStyle = .none

        photoView.contentMode = .scaleAspectFill
        photoView.clipsToBounds = true
        photoView.layer.cornerRadius = 12
        photoView.backgroundColor = .secondarySystemBackground

        noteLabel.font = .preferredFont(forTextStyle: .body)
        noteLabel.adjustsFontForContentSizeCategory = true
        noteLabel.numberOfLines = 0

        metaLabel.font = .preferredFont(forTextStyle: .footnote)
        metaLabel.adjustsFontForContentSizeCategory = true
        metaLabel.textColor = .secondaryLabel
        metaLabel.numberOfLines = 0

        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        [photoView, noteLabel, metaLabel].forEach { stack.addArrangedSubview($0) }
        contentView.addSubview(stack)

        photoHeight = photoView.heightAnchor.constraint(equalToConstant: 220)
        photoHeight.priority = .init(999)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            stack.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor),
            photoHeight
        ])
    }

    func configure(with memory: Memory, placeName: String?, dateText: String) {
        if let fileName = memory.imageFileName, let image = PhotoStore.shared.image(named: fileName) {
            photoView.image = image
            photoView.isHidden = false
        } else {
            photoView.image = nil
            photoView.isHidden = true
        }

        let note = memory.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        noteLabel.text = note
        noteLabel.isHidden = note.isEmpty

        metaLabel.text = [placeName.map { "📍 \($0)" }, dateText].compactMap { $0 }.joined(separator: "  •  ")
    }
}
