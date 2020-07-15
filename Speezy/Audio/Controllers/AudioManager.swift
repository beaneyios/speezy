//
//  AudioManager.swift
//  Speezy
//
//  Created by Matt Beaney on 14/07/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import Foundation
import AVKit

class AudioManager: NSObject {
    private(set) var item: AudioItem
    private(set) var trimmedItem: AudioItem?
    
    private(set) var state = State.idle {
        didSet { stateDidChange() }
    }
    
    var duration: TimeInterval {
        let asset = AVAsset(url: item.url)
        let duration = CMTimeGetSeconds(asset.duration)
        return TimeInterval(duration)
    }
    
    private var observations = [ObjectIdentifier : Observation]()
    private var player: AVAudioPlayer?
    private var timer: Timer?
    
    init(item: AudioItem) {
        self.item = item
        self.player = try? AVAudioPlayer(contentsOf: item.url)
        
        super.init()
        self.player?.delegate = self
    }
    
    private func stateDidChange() {
        observations.forEach {
            guard let observer = $0.value.observer else {
                observations.removeValue(forKey: $0.key)
                return
            }

            switch state {
            case .idle:
                observer.audioPlayerDidStop(self)
            case .playing(let item):
                observer.audioPlayer(self, didStartPlaying: item)
            case .paused(let item):
                observer.audioPlayer(self, didPausePlaybackOf: item)
            }
        }
    }
}

// MARK: Playback
extension AudioManager {
    func play() {
        state = .playing(item)
        player?.play()
        startTimer()
    }

    func pause() {
        switch state {
        case .idle, .paused:
            break
        case .playing(let item):
            state = .paused(item)
            player?.pause()
        }
        
        timer?.invalidate()
    }

    func stop() {
        state = .idle
        timer?.invalidate()
    }
    
    private func startTimer() {
        self.timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { (timer) in
            guard let player = self.player else {
                assertionFailure("Player nil for some reason")
                return
            }
            
            self.observations.forEach {
                guard let observer = $0.value.observer else {
                    self.observations.removeValue(forKey: $0.key)
                    return
                }
                
                observer.audioPlayer(self, progressedWithTime: player.currentTime)
            }
        }
    }
}

// MARK: Editing
extension AudioManager {
    func trim(from: TimeInterval, to: TimeInterval) {
        AudioEditor.trim(fileURL: item.url, startTime: from, stopTime: to) { (url) in
            let trimmedItem = AudioItem(url: url)
            self.trimmedItem = trimmedItem
            
            self.player = try? AVAudioPlayer(contentsOf: url)
            
            self.observations.forEach {
                guard let observer = $0.value.observer else {
                    self.observations.removeValue(forKey: $0.key)
                    return
                }
                
                observer.audioPlayer(self, didCreateTrimmedItem: trimmedItem)
            }
        }
    }
    
    func applyTrim() {
        guard let trimmedItem = self.trimmedItem else {
            return
        }
        
        self.item = trimmedItem
        
        self.observations.forEach {
            guard let observer = $0.value.observer else {
                self.observations.removeValue(forKey: $0.key)
                return
            }
            
            observer.audioPlayer(self, didApplyTrimmedItem: trimmedItem)
        }
    }
    
    func cancelTrim() {
        trimmedItem = nil
        
        self.observations.forEach {
            guard let observer = $0.value.observer else {
                self.observations.removeValue(forKey: $0.key)
                return
            }
            
            observer.audioPlayerDidCancelTrim(self)
        }
    }
}

extension AudioManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        state = .idle
        stateDidChange()
    }
}

extension AudioManager {
    func togglePlayback() {
        switch state {
        case .playing:
            self.pause()
        case .paused, .idle:
            self.play()
        }
    }
}

extension AudioManager {
    func addObserver(_ observer: AudioManagerObserver) {
        let id = ObjectIdentifier(observer)
        observations[id] = Observation(observer: observer)
    }

    func removeObserver(_ observer: AudioManagerObserver) {
        let id = ObjectIdentifier(observer)
        observations.removeValue(forKey: id)
    }
}

extension AudioManager {
    enum State {
        case idle
        case playing(AudioItem)
        case paused(AudioItem)
    }
    
    struct Observation {
        weak var observer: AudioManagerObserver?
    }
}
