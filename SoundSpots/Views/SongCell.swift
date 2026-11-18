//
//  SongCell.swift
//  SoundSpots
//

import UIKit

/// Gives each cell class a reuse identifier that matches its class name.
protocol ReuseIdentifiable {
    static var reuseIdentifier: String { get }
}

extension ReuseIdentifiable {
    static var reuseIdentifier: String { String(describing: self) }
}

/// Prototype cell laid out in Main.storyboard: artwork | title / artist / detail.
final class SongCell: UITableViewCell, ReuseIdentifiable {

    @IBOutlet private weak var artworkImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var artistLabel: UILabel!
    @IBOutlet private weak var detailLabel: UILabel!

    private var imageTask: URLSessionDataTask?
    private static let placeholder = UIImage(systemName: "music.note")

    override func awakeFromNib() {
        super.awakeFromNib()
        artworkImageView.layer.cornerRadius = 8
        artworkImageView.clipsToBounds = true
        artworkImageView.backgroundColor = .secondarySystemBackground
        artworkImageView.tintColor = .tertiaryLabel
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageTask?.cancel()
        imageTask = nil
        showPlaceholder()
    }

    /// `detail` is optional: search results don't need a third line.
    func configure(with song: Song, detail: String?, rank: Int? = nil) {
        if let rank = rank {
            titleLabel.text = "\(rank). \(song.title)"
        } else {
            titleLabel.text = song.title
        }
        artistLabel.text = song.artist
        detailLabel.text = detail
        detailLabel.isHidden = (detail == nil)

        showPlaceholder()
        imageTask = ImageLoader.shared.loadImage(from: song.artworkURL(size: 200)) { [weak self] image in
            guard let self = self, let image = image else { return }
            self.artworkImageView.contentMode = .scaleAspectFill
            self.artworkImageView.image = image
        }
    }

    private func showPlaceholder() {
        artworkImageView.image = Self.placeholder
        artworkImageView.contentMode = .center
    }
}
