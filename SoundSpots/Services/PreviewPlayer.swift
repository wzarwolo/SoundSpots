//
//  PreviewPlayer.swift
//  SoundSpots
//
//  Plays the 30-second preview clips that the iTunes API provides.
//

import AVFoundation

extension Notification.Name {
    static let previewPlayerDidChange = Notification.Name("previewPlayerDidChange")
}

final class PreviewPlayer {

    static let shared = PreviewPlayer()

    private var player: AVPlayer?
    private var endObserver: NSObjectProtocol?

    /// The song currently playing, if any (an Optional the UI checks).
    private(set) var currentSong: Song?

    func isPlaying(_ song: Song) -> Bool {
        currentSong?.id == song.id
    }

    /// Starts the song, or stops it if it's already playing. Returns false if there's no preview.
    @discardableResult
    func toggle(_ song: Song) -> Bool {
        if isPlaying(song) {
            stop()
            return true
        }
        guard let url = song.previewURL else { return false }

        stop()
        try? AVAudioSession.sharedInstance().setCategory(.playback)
        try? AVAudioSession.sharedInstance().setActive(true)

        let item = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: item)
        currentSong = song
        endObserver = NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime,
                                                             object: item, queue: .main) { [weak self] _ in
            self?.stop()
        }
        player?.play()
        NotificationCenter.default.post(name: .previewPlayerDidChange, object: self)
        return true
    }

    func stop() {
        player?.pause()
        player = nil
        if let observer = endObserver {
            NotificationCenter.default.removeObserver(observer)
            endObserver = nil
        }
        guard currentSong != nil else { return }
        currentSong = nil
        NotificationCenter.default.post(name: .previewPlayerDidChange, object: self)
    }
}
