//
//  AudioManager.swift
//  Speezy
//
//  Created by Matt Beaney on 14/07/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import Foundation
import AVKit
import UIKit

class AudioManager: NSObject {
    private(set) var item: AudioItem
    private(set) var originalItem: AudioItem
    private(set) var state = State.idle
    
    var duration: TimeInterval {
        let asset = AVAsset(url: originalItem.url)
        let duration = CMTimeGetSeconds(asset.duration)
        return TimeInterval(duration)
    }
    
    var currentPlaybackTime: TimeInterval {
        audioPlayer?.currentPlaybackTime ?? 0.0
    }
    
    var isCropping: Bool {
        audioCropper != nil
    }
    
    var hasActiveCrop: Bool {
        audioCropper?.hasActiveCrop ?? false
    }
    
    var currentImageAttachment: UIImage? {
        audioAttachmentManager.imageAttachmentCache[item.id]
    }
    
    var hasRecorded: Bool {
        item.duration > 0
    }
    
    private var firstRecord = true
    private var recordingStoppedAutomatically = false
    var shouldAutomaticallyShowTitleSelector: Bool {
        let firstRecord = self.firstRecord
        self.firstRecord = false
        return firstRecord && item.title == "No title" && recordingStoppedAutomatically == false
    }
    
    private var observations = [ObjectIdentifier : Observation]()
    
    private var audioPlayer: AudioPlayer?
    private var audioRecorder: AudioRecorder?
    private var audioCropper: AudioCropper?
    private let audioAttachmentManager = AudioAttachmentManager()
    
    init(item: AudioItem) {
        self.originalItem = item
        self.item = item
    }
    
    func updateTitle(title: String) {
        let audioItem = AudioItem(
            id: item.id,
            path: item.path,
            title: title,
            date: item.date,
            tags: item.tags
        )
        
        self.item = audioItem
        self.originalItem = audioItem
        
        AudioStorage.saveItem(audioItem)
    }
    
    func addTag(title: String) {
        let tag = Tag(id: UUID().uuidString, title: title)
                
        let newItem = AudioItem(
            id: item.id,
            path: item.path,
            title: item.title,
            date: item.date,
            tags: item.tags + [tag]
        )
        
        self.item = newItem
        self.originalItem = newItem
        
        AudioStorage.saveItem(newItem)
    }
    
    func setImageAttachment(_ attachment: UIImage?, completion: @escaping () -> Void) {
        audioAttachmentManager.storeAttachment(
            attachment,
            forItem: item,
            completion: completion
        )
    }
    
    func fetchImageAttachment(completion: @escaping (UIImage?) -> Void) {
        audioAttachmentManager.fetchAttachment(forItem: item, completion: completion)
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
        recordingStoppedAutomatically = false
        
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
    
    func audioRecorder(_ recorder: AudioRecorder, didRecordBarWithPower power: Float, stepDuration: TimeInterval, totalDuration: TimeInterval) {
        observations.forEach {
            guard let observer = $0.value.observer else {
                self.observations.removeValue(forKey: $0.key)
                return
            }

            observer.audioManager(
                self,
                didRecordBarWithPower: power,
                stepDuration: stepDuration,
                totalDuration: totalDuration
            )
        }
    }
    
    func audioRecorder(_ recorder: AudioRecorder, didFinishRecordingWithCompletedItem item: AudioItem) {
        self.originalItem = item
        self.item = item
        
        state = .stoppedRecording(item)
        stateDidChange()
        
        AudioStorage.saveItem(item)
    }
    
    func audioRecorder(_ recorder: AudioRecorder, didReachMaxRecordLimitWithItem item: AudioItem) {
        recordingStoppedAutomatically = true
        
        observations.forEach {
            guard let observer = $0.value.observer else {
                self.observations.removeValue(forKey: $0.key)
                return
            }

            observer.audioManager(self, didReachMaxRecordingLimitWithItem: item)
        }
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
        if state.shouldRegeneratePlayer == true {
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
    
    func seek(to percentage: Float) {
        if audioPlayer == nil {
            audioPlayer = AudioPlayer(item: item)
            audioPlayer?.delegate = self
            state = .pausedPlayback(item)
        }
        
        audioPlayer?.seek(to: percentage)
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
            
            observer.audioManager(self, progressedWithTime: time)
        }
    }
    
    func audioPlayerDidFinishPlayback(_ player: AudioPlayer) {
        audioPlayer = nil
        state = .stoppedPlayback(item)
        stateDidChange()
    }
}

// MARK: Editing
extension AudioManager: AudioCropperDelegate {
    func toggleCrop() {
        if isCropping {
            if hasActiveCrop {
                confirmCrop()
            } else {
                cancelCrop()
            }
        } else {
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
    
    func confirmCrop() {
        state = .confirmingCrop(item)
        stateDidChange()
    }
    
    func audioCropper(_ cropper: AudioCropper, didAdjustCroppedItem item: AudioItem) {
        self.item = item
        state = .adjustedCropping(item)
        stateDidChange()
    }
    
    func audioCropper(_ cropper: AudioCropper, didApplyCroppedItem item: AudioItem) {
        
        FileManager.default.deleteExistingFile(with: "\(item.id).m4a")
        FileManager.default.renameFile(from: "\(item.id)_cropped.m4a", to: "\(item.id).m4a")
        
        let completeItem = AudioItem(
            id: item.id,
            path: "\(item.id).m4a",
            title: item.title,
            date: item.date,
            tags: item.tags
        )
        
        self.item = completeItem
        self.originalItem = completeItem
        
        state = .croppingFinished(item)
        stateDidChange()
        audioCropper = nil
        
        AudioStorage.saveItem(item)
    }
    
    func audioCropper(_ cropper: AudioCropper, didCancelCropReturningToItem item: AudioItem) {
        self.item = item
        state = .cancelledCropping(item)
        stateDidChange()
        audioCropper = nil
        
        AudioStorage.saveItem(item)
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
        case confirmingCrop(AudioItem)
        
        case stoppedPlayback(AudioItem)
        case startedPlayback(AudioItem)
        case pausedPlayback(AudioItem)
        
        case startedRecording(AudioItem)
        case processingRecording(AudioItem)
        case stoppedRecording(AudioItem)
        
        var shouldRegeneratePlayer: Bool {
            switch self {
            case .pausedPlayback:
                return false
            default:
                return true
            }
        }
        
        var isInPlayback: Bool {
            switch self {
            case .startedPlayback, .pausedPlayback, .stoppedPlayback:
                return true
            default:
                return false
            }
        }
        
        var isRecording: Bool {
            switch self {
            case .startedRecording, .stoppedRecording, .processingRecording:
                return true
            default:
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
                observer.audioManager(self, didStartCroppingItem: item)
            case .adjustedCropping(let item):
                observer.audioManager(self, didAdjustCropOnItem: item)
            case .cancelledCropping:
                observer.audioManagerDidCancelCropping(self)
            case .croppingFinished(let item):
                observer.audioManager(self, didFinishCroppingItem: item)
            case .confirmingCrop(let item):
                observer.audioManager(self, didConfirmCropOnItem: item)
                
            case .stoppedPlayback(let item):
                observer.audioManager(self, didStopPlaying: item)
            case .startedPlayback(let item):
                observer.audioManager(self, didStartPlaying: item)
            case .pausedPlayback(let item):
                observer.audioManager(self, didPausePlaybackOf: item)
            
            case .startedRecording:
                observer.audioManagerDidStartRecording(self)
            case .stoppedRecording:
                observer.audioManagerDidStopRecording(self)
            case .processingRecording:
                observer.audioManagerProcessingRecording(self)
            }
        }
    }
}
