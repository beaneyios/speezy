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

enum PlaybackSpeed {
    case one
    case onePointThree
    case onePointFive
    
    var next: PlaybackSpeed {
        switch self {
        case .one: return .onePointThree
        case .onePointThree: return .onePointFive
        case .onePointFive: return .one
        }
    }
    
    var rate: Float {
        switch self {
        case .one: return 1.0
        case .onePointThree: return 1.3
        case .onePointFive: return 1.5
        }
    }
    
    var label: String {
        switch self {
        case .one: return "1x"
        case .onePointThree: return "1.3x"
        case .onePointFive: return "1.5x"
        }
    }
}

class AudioPlayer: NSObject, AVAudioPlayerDelegate {
    var currentPlaybackTime: TimeInterval {
        player?.currentTime ?? 0.0
    }
    
    weak var delegate: AudioPlayerDelegate?
    
    private var player: AVAudioPlayer?
    private var playbackTimer: Timer?
    private(set) var playbackSpeed: PlaybackSpeed?
    
    init(item: AudioItem) {
        print("initting player")
        player = try? AVAudioPlayer(contentsOf: item.fileUrl)
        super.init()
        player?.delegate = self
    }
    
    func play() {
        guard let player = player else {
            return
        }
        
        //karl added - Prevent sleep function after 45sec (will be reenabled after playbakc)
        UIApplication.shared.isIdleTimerDisabled = true
        
        AVAudioSession.sharedInstance().prepareForPlayback()
        player.enableRate = true
        player.play()
        
        startPlaybackTimer()
        delegate?.audioPlayerDidBeginPlayback(self)
    }
    
    func adjustPlaybackSpeed(speed: PlaybackSpeed) {
        playbackSpeed = speed
        player?.rate = speed.rate
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
    
    func seek(to time: TimeInterval) {
        guard let player = self.player else {
            
            assertionFailure("Somehow the skip is getting called despite the player being nil")
            return
        }
        
        player.currentTime = time
        delegate?.audioPlayer(self, progressedPlaybackWithTime: player.currentTime, seekActive: true)
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        
        //karl added - Reenable sleep function
        UIApplication.shared.isIdleTimerDisabled = false
        
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
