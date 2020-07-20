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
    private(set) var originalItem: AudioItem
    private(set) var trimmedItem: AudioItem?
    
    private(set) var state = State.idle
    
    var duration: TimeInterval {
        let asset = AVAsset(url: item.url)
        let duration = CMTimeGetSeconds(asset.duration)
        return TimeInterval(duration)
    }
    
    var currentPlaybackTime: TimeInterval {
        audioPlayer?.currentPlaybackTime ?? 0.0
    }
    
    private var observations = [ObjectIdentifier : Observation]()
    
    private var audioPlayer: AudioPlayer?
    private var audioRecorder: AudioRecorder?
    
    init(item: AudioItem) {
        self.originalItem = item
        self.item = item
    }
    
    private func stateDidChange() {
        observations.forEach {
            guard let observer = $0.value.observer else {
                observations.removeValue(forKey: $0.key)
                return
            }

            switch state {
            case .idle:
                break
                
            case .trimmingStarted(let item):
                observer.audioPlayer(self, didCreateTrimmedItem: item)
            case .trimmingCancelled:
                observer.audioPlayerDidCancelTrim(self)
            case .trimmingApplied(let item):
                observer.audioPlayer(self, didApplyTrimmedItem: item)
                
            case .stoppedPlayback:
                observer.audioPlayerDidStop(self)
            case .startedPlayback(let item):
                observer.audioPlayer(self, didStartPlaying: item)
            case .pausedPlayback(let item):
                observer.audioPlayer(self, didPausePlaybackOf: item)
            
            case .startedRecording:
                observer.audioPlayerDidStartRecording(self)
            case .stoppedRecording:
                observer.audioPlayerDidStopRecording(self)
            case .processingRecording:
                observer.audioPlayerProcessingRecording(self)
            }
        }
    }
}

// MARK: Recording
extension AudioManager: AudioRecorderDelegate {
    func toggleRecording() {
        switch state {
        case .startedRecording:
            stopRecording()
        default:
            startRecording()
        }
    }
    
    func startRecording() {
        let audioRecorder = AudioRecorder(item: item)
        audioRecorder.delegate = self
        audioRecorder.record()
        self.audioRecorder = audioRecorder
    }
    
    func stopRecording() {
        audioRecorder?.stopRecording()
    }
    
    func audioRecorderDidStartRecording(_ recorder: AudioRecorder) {
        state = .startedRecording(item)
        stateDidChange()
    }
    
    func audioRecorderDidStartProcessingRecording(_ recorder: AudioRecorder) {
        state = .processingRecording(item)
        stateDidChange()
    }
    
    func audioRecorder(_ recorder: AudioRecorder, didRecordBarWithPower power: Float, duration: TimeInterval) {
        observations.forEach {
            guard let observer = $0.value.observer else {
                self.observations.removeValue(forKey: $0.key)
                return
            }

            observer.audioPlayer(self, didRecordBarWithPower: power, duration: duration)
        }
    }
    
    func audioRecorder(_ recorder: AudioRecorder, didFinishRecordingWithCompletedItem item: AudioItem) {
        state = .stoppedRecording(item)
        stateDidChange()
    }
}

// MARK: Playback
extension AudioManager: AudioPlayerDelegate {
    func togglePlayback() {
        switch state {
        case .startedPlayback:
            pause()
        default:
            play()
        }
    }
    
    func play() {
        if state.isPaused == false {
            audioPlayer = AudioPlayer(item: trimmedItem ?? item)
            audioPlayer?.delegate = self
        }
        
        audioPlayer?.play()
    }
    
    func pause() {
        switch state {
        case .startedPlayback:
            audioPlayer?.pause()
        default:
            break
        }
    }

    func stop() {
        audioPlayer?.stop()
    }
    
    func audioPlayerDidStartPlayback(_ player: AudioPlayer) {
        state = .startedPlayback(item)
        stateDidChange()
    }
    
    func audioPlayerDidPausePlayback(_ player: AudioPlayer) {
        state = .pausedPlayback(item)
        stateDidChange()
    }
    
    func audioPlayer(_ player: AudioPlayer, progressedWithTime time: TimeInterval) {
        self.observations.forEach {
            guard let observer = $0.value.observer else {
                self.observations.removeValue(forKey: $0.key)
                return
            }
            
            observer.audioPlayer(self, progressedWithTime: time)
        }
    }
    
    func audioPlayerDidFinishPlayback(_ player: AudioPlayer) {
        state = .stoppedPlayback
        stateDidChange()
    }
}

// MARK: Editing
extension AudioManager {
    func trim(from: TimeInterval, to: TimeInterval) {
        AudioEditor.trim(fileURL: item.url, startTime: from, stopTime: to) { (url) in
            let trimmedItem = AudioItem(id: self.item.id, url: url)
            self.trimmedItem = trimmedItem
            self.state = .trimmingStarted(trimmedItem)
            self.stateDidChange()
        }
    }
    
    func applyTrim() {
        guard let trimmedItem = self.trimmedItem else {
            return
        }
        
        self.item = trimmedItem
        self.state = .trimmingApplied(trimmedItem)
        self.stateDidChange()
    }
    
    func cancelTrim() {
        trimmedItem = nil
        state = .trimmingCancelled(self.item)
        stateDidChange()
    }
}

// MARK: State management
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
        
        case trimmingStarted(AudioItem)
        case trimmingCancelled(AudioItem)
        case trimmingApplied(AudioItem)
        
        case stoppedPlayback
        case startedPlayback(AudioItem)
        case pausedPlayback(AudioItem)
        
        case startedRecording(AudioItem)
        case processingRecording(AudioItem)
        case stoppedRecording(AudioItem)
        
        var isPaused: Bool {
            if case State.pausedPlayback = self {
                return true
            } else {
                return false
            }
        }
    }
    
    struct Observation {
        weak var observer: AudioManagerObserver?
    }
}
