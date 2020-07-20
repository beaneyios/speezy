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
    func toggleCropping() {
        switch state {
        case .startedCropping, .adjustedCropping:
            cancelCrop()
        default:
            startCropping()
        }
    }
    
    func startCropping() {
        audioCropper = AudioCropper(originalItem: item)
        audioCropper?.delegate = self
        state = .startedCropping(item)
        stateDidChange()
    }
    
    func crop(from: TimeInterval, to: TimeInterval) {
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
        state = .adjustedCropping(item)
        stateDidChange()
    }
    
    func audioCropper(_ cropper: AudioCropper, didApplyCroppedItem item: AudioItem) {
        self.item = item
        state = .croppingFinished(item)
        stateDidChange()
        audioCropper = nil
    }
    
    func audioCropper(_ cropper: AudioCropper, didCancelCropReturningToItem item: AudioItem) {
        self.item = item
        state = .cancelledCropping(item)
        stateDidChange()
        audioCropper = nil
    }
}

// MARK: State management
extension AudioManager {
    struct Observation {
        weak var observer: AudioManagerObserver?
    }
    
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
        
        case startedCropping(AudioItem)
        case adjustedCropping(AudioItem)
        case cancelledCropping(AudioItem)
        case croppingFinished(AudioItem)
        
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
    
    private func stateDidChange() {
        observations.forEach {
            guard let observer = $0.value.observer else {
                observations.removeValue(forKey: $0.key)
                return
            }

            switch state {
            case .idle:
                break
                
            case .startedCropping(let item):
                observer.audioPlayer(self, didStartCroppingItem: item)
            case .adjustedCropping(let item):
                observer.audioPlayer(self, didAdjustCropOnItem: item)
            case .cancelledCropping:
                observer.audioPlayerDidCancelCropping(self)
            case .croppingFinished(let item):
                observer.audioPlayer(self, didFinishCroppingItem: item)
                
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
