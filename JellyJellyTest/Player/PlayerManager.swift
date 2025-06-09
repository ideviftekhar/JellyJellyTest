//
//  PlayerManager.swift
//

import AVFoundation

class PlayerManager {

    private var playerCollection = [Int: AVPlayer]()

    static let shared = PlayerManager()

    func player(for media: Post?) -> AVPlayer? {
        guard let media = media,
              let videoUrl = media.videoUrl, let url = URL(string: videoUrl) else { return nil }

        if let id = media.postId {
            if let existing = playerCollection[id] {
                return existing
            } else {
                let item = AVPlayerItem(url: url)
                let player = AVPlayer(playerItem: item)
                player.allowsExternalPlayback = true
                player.preventsDisplaySleepDuringVideoPlayback = true
                playerCollection[id] = player
                return player
            }
        } else {
            return nil
        }
    }
}

