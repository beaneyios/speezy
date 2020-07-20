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
    private var audioCropper: AudioCropper?
    
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
            audioPlayer = AudioPlayer(item: item)
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
extension AudioManager: AudioCropperDelegate {
    func crop(from: TimeInterval, to: TimeInterval) {
        if audioCropper == nil {
            audioCropper = AudioCropper(originalItem: item)
            audioCropper?.delegate = self
        }
        
        audioCropper?.crop(from: from, to: to)
    }
    
    func applyCrop() {
        audioCropper?.applyCrop()
    }
    
    func cancelCrop() {
        audioCropper?.cancelCrop()
    }
    
    func audioCropper(_ cropper: AudioCropper, didCreateCroppedItem item: AudioItem) {
        self.item = item
        state = .trimmingStarted(item)
        stateDidChange()
    }
    
    func audioCropper(_ cropper: AudioCropper, didApplyCroppedItem item: AudioItem) {
        self.item = item
        state = .trimmingApplied(item)
        stateDidChange()
        audioCropper = nil
    }
    
    func audioCropper(_ cropper: AudioCropper, didCancelCropReturningToItem item: AudioItem) {
        self.item = item
        state = .trimmingCancelled(item)
        stateDidChange()
        audioCropper = nil
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
