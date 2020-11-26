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
    func audioPlayerDidBeginPlayback(_ player: AudioPlayer)
    func audioPlayerDidPausePlayback(_ player: AudioPlayer)
    func audioPlayerDidStopPlayback(_ player: AudioPlayer)
    func audioPlayer(
        _ player: AudioPlayer,
        progressedPlaybackWithTime time: TimeInterval,
        seekActive: Bool
    )
}

class AudioPlayer: NSObject, AVAudioPlayerDelegate {
    var currentPlaybackTime: TimeInterval {
        player?.currentTime ?? 0.0
    }
    
    weak var delegate: AudioPlayerDelegate?
    
    private var player: AVAudioPlayer?
    private var playbackTimer: Timer?
    
    init(item: AudioItem) {
        print("initting player")
        player = try? AVAudioPlayer(contentsOf: item.url)
        super.init()
        player?.delegate = self
    }
    
    func play() {
        guard let player = player else {
            return
        }
        
        AVAudioSession.sharedInstance().prepareForPlayback()
        player.play()
        startPlaybackTimer()
        delegate?.audioPlayerDidBeginPlayback(self)
    }
    
    func pause() {
        player?.pause()
        playbackTimer?.invalidate()
        delegate?.audioPlayerDidPausePlayback(self)
    }

    func stop() {
        player?.stop()
        player?.currentTime = 0.0
        playbackTimer?.invalidate()
        playbackTimer = nil
        delegate?.audioPlayerDidStopPlayback(self)
    }
    
    func seek(to percentage: Float) {
        guard let player = self.player else {
            
            assertionFailure("Somehow the skip is getting called despite the player being nil")
            return
        }
        
        let timePosition = player.duration * TimeInterval(percentage)
        player.currentTime = timePosition
        print(" ")
        print("Time position \(timePosition)")
        print("Duration \(player.duration)")
        print(" ")
        
        delegate?.audioPlayer(self, progressedPlaybackWithTime: player.currentTime, seekActive: true)
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        stop()
    }
    
    private func startPlaybackTimer() {
        self.playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { (timer) in
            guard let player = self.player else {
                assertionFailure("Player nil for some reason")
                return
            }
            
            self.delegate?.audioPlayer(self, progressedPlaybackWithTime: player.currentTime, seekActive: false)
        }
    }
}
