//
//  AudioPlayer.swift
//  Speezy
//
//  Created by Matt Beaney on 20/07/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import Foundation
import AVKit

protocol AudioPlayerDelegate: AnyObject {
    func audioPlayerDidStartPlayback(_ player: AudioPlayer)
    func audioPlayerDidPausePlayback(_ player: AudioPlayer)
    func audioPlayer(_ player: AudioPlayer, progressedWithTime time: TimeInterval)
}

class AudioPlayer: NSObject, AVAudioPlayerDelegate {
    var currentPlaybackTime: TimeInterval {
        player?.currentTime ?? 0.0
    }
    
    weak var delegate: AudioPlayerDelegate?
    
    private var player: AVAudioPlayer?
    private var playbackTimer: Timer?
    
    init(item: AudioItem) {
        player = try? AVAudioPlayer(contentsOf: item.url)
    }
    
    func play() {
        player?.play()
        startPlaybackTimer()
        delegate?.audioPlayerDidStartPlayback(self)
    }
    
    func pause() {
        player?.pause()
        playbackTimer?.invalidate()
        delegate?.audioPlayerDidPausePlayback(self)
    }

    func stop() {
        playbackTimer?.invalidate()
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        playbackTimer?.invalidate()
        playbackTimer = nil
    }
    
    private func startPlaybackTimer() {
        self.playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { (timer) in
            guard let player = self.player else {
                assertionFailure("Player nil for some reason")
                return
            }
            
            self.delegate?.audioPlayer(self, progressedWithTime: player.currentTime)
        }
    }
}
