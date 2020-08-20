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
    private(set) var hasUnsavedChanges: Bool = false
    
    var currentImageAttachment: UIImage? {
        audioAttachmentManager.imageAttachmentCache[item.id]
    }
    
    private var firstRecord = true
    var shouldAutomaticallyShowTitleSelector: Bool {
        let firstRecord = self.firstRecord
        self.firstRecord = false
        return firstRecord && item.title == "No title"
    }
    
    private var observations = [ObjectIdentifier : Observation]()
    
    private var audioPlayer: AudioPlayer?
    private var audioRecorder: AudioRecorder?
    private var audioCropper: AudioCropper?
    private let audioAttachmentManager = AudioAttachmentManager()
    
    init(item: AudioItem) {
        self.originalItem = item
        
        self.item = AudioItem(
            id: item.id,
            path: "\(item.id)_staging.m4a",
            title: item.title,
            date: item.date,
            tags: item.tags
        )
    }
    
    func createStagingFile() {
        DispatchQueue.global().async {
            do {
                try FileManager.default.copyItem(at: self.originalItem.url, to: self.item.url)
            } catch {
                print(error)
            }
        }
    }
    
    func save(completion: (AudioItem) -> Void) {
        FileManager.default.deleteExistingFile(with: self.originalItem.path)
        FileManager.default.copy(original: item.url, to: originalItem.url)
        
        let newItem = AudioItem(
            id: item.id,
            path: "\(item.id).m4a",
            title: item.title,
            date: item.date,
            tags: item.tags
        )
        
        AudioStorage.saveItem(newItem)
        completion(newItem)
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
    var hasRecorded: Bool {
        item.duration > 0
    }
    
    func toggleRecording() {
        switch state {
        case .recording:
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
        performAction(action: .showRecordingStarted(item))
    }
    
    func audioRecorderDidStartProcessingRecording(_ recorder: AudioRecorder) {
        performAction(action: .showRecordingProcessing(item))
    }
    
    func audioRecorder(_ recorder: AudioRecorder, didRecordBarWithPower power: Float, stepDuration: TimeInterval, totalDuration: TimeInterval) {
        performAction(
            action: .showRecordingProgressed(
                power: power,
                stepDuration: stepDuration,
                totalDuration: totalDuration
            )
        )
    }
    
    func audioRecorder(_ recorder: AudioRecorder, didFinishRecordingWithCompletedItem item: AudioItem, maxLimitReached: Bool) {
        self.item = item
        
        performAction(
            action: .showRecordingStopped(item, maxLimitReached: maxLimitReached)
        )
        
        hasUnsavedChanges = true
    }
}

// MARK: Playback
extension AudioManager: AudioPlayerDelegate {
    var currentItem: AudioItem {
        audioCropper?.croppedItem ?? item
    }
    
    var startPosition: TimeInterval {
        audioCropper?.cropFrom ?? 0.0
    }
    
    var duration: TimeInterval {
        let asset = AVAsset(url: item.url)
        let duration = CMTimeGetSeconds(asset.duration)
        return TimeInterval(duration)
    }
    
    var currentPlaybackTime: TimeInterval {
        audioPlayer?.currentPlaybackTime ?? 0.0
    }
    
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
            audioPlayer = AudioPlayer(item: currentItem)
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
            audioPlayer = AudioPlayer(item: currentItem)
            audioPlayer?.delegate = self
            state = .pausedPlayback(currentItem)
        }
        
        audioPlayer?.seek(to: percentage)
    }

    func stop() {
        audioPlayer?.stop()
    }
    
    func audioPlayerDidStartPlayback(_ player: AudioPlayer) {
        performAction(action: .showPlaybackStarted(item))
    }
    
    func audioPlayerDidPausePlayback(_ player: AudioPlayer) {
        performAction(action: .showPlaybackPaused(item))
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
        performAction(action: .showPlaybackStopped(item))
    }
}

// MARK: CROPPING
extension AudioManager: AudioCropperDelegate {
    var isCropping: Bool {
        audioCropper != nil
    }
    
    var canCrop: Bool {
        currentItem.duration > 3.0
    }
    
    var hasActiveCrop: Bool {
        guard let croppedItemDuration = audioCropper?.croppedItem?.duration else {
            return false
        }
        
        return croppedItemDuration != item.duration
    }
    
    func toggleCrop() {
        startCropping()
    }
    
    func startCropping() {
        audioCropper = AudioCropper(item: item)
        audioCropper?.delegate = self
        performAction(action: .showCrop(item))
    }
    
    func crop(from: TimeInterval, to: TimeInterval) {
        audioCropper?.crop(from: from, to: to)
    }
    
    func leftCropHandleMoved(to percentage: CGFloat) {
        observations.forEach {
            $0.value.observer?.audioManager(self, didMoveLeftCropHandleTo: percentage)
        }
    }
    
    func rightCropHandleMoved(to percentage: CGFloat) {
        observations.forEach {
            $0.value.observer?.audioManager(self, didMoveRightCropHandleTo: percentage)
        }
    }
    
    func applyCrop() {
        audioCropper?.applyCrop()
    }
    
    func cancelCrop() {
        stop()
        audioCropper?.cancelCrop()
    }
    
    func audioCropper(_ cropper: AudioCropper, didAdjustCroppedItem item: AudioItem) {
        performAction(action: .showCropAdjusted(item))
    }
    
    func audioCropper(_ cropper: AudioCropper, didApplyCroppedItem item: AudioItem) {
        
        FileManager.default.deleteExistingFile(with: self.item.path)
        FileManager.default.renameFile(from: "\(item.id)_cropped.m4a", to: self.item.path)
        
        performAction(action: .showCropFinished(item))
        audioCropper = nil
        
        hasUnsavedChanges = true
    }
    
    func audioCropper(_ cropper: AudioCropper, didCancelCropReturningToItem item: AudioItem) {
        self.item = item
        performAction(action: .showCropCancelled(item))
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
    enum Action {
        case showCrop(AudioItem)
        case showCropAdjusted(AudioItem)
        case showCropCancelled(AudioItem)
        case showCropFinished(AudioItem)
        
        case showPlaybackStopped(AudioItem)
        case showPlaybackStarted(AudioItem)
        case showPlaybackPaused(AudioItem)
        
        case showRecordingStarted(AudioItem)
        case showRecordingProgressed(power: Float, stepDuration: TimeInterval, totalDuration: TimeInterval)
        case showRecordingProcessing(AudioItem)
        case showRecordingStopped(AudioItem, maxLimitReached: Bool)
    }
    
    enum State {
        case idle
    
        case stoppedPlayback(AudioItem)
        case startedPlayback(AudioItem)
        case pausedPlayback(AudioItem)
        
        case cropping
        case recording
        
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
            case .recording:
                return true
            default:
                return false
            }
        }
    }
    
    func performAction(action: Action) {
        observations.forEach {
            guard let observer = $0.value.observer else {
                observations.removeValue(forKey: $0.key)
                return
            }
            
            switch action {
            case .showCrop(let item):
                state = .cropping
                observer.audioManager(self, didStartCroppingItem: item)
                
            case .showCropAdjusted(let item):
                observer.audioManager(self, didAdjustCropOnItem: item)
                
            case .showCropCancelled:
                state = .idle
                observer.audioManagerDidCancelCropping(self)
                
            case .showCropFinished(let item):
                state = .idle
                observer.audioManager(self, didFinishCroppingItem: item)
                
            case .showPlaybackStopped(let item):
                state = .stoppedPlayback(item)
                observer.audioManager(self, didStopPlaying: item)
                
            case .showPlaybackStarted(let item):
                state = .startedPlayback(item)
                observer.audioManager(self, didStartPlaying: item)
                
            case .showPlaybackPaused(let item):
                state = .pausedPlayback(item)
                observer.audioManager(self, didPausePlaybackOf: item)
                
            case .showRecordingStarted:
                state = .recording
                observer.audioManagerDidStartRecording(self)
            
            case let .showRecordingProgressed(power, stepDuration, totalDuration):
                observer.audioManager(
                    self,
                    didRecordBarWithPower: power,
                    stepDuration: stepDuration,
                    totalDuration: totalDuration
                )
                
            case .showRecordingProcessing:
                observer.audioManagerProcessingRecording(self)
                
            case let .showRecordingStopped(_, maxLimitReached):
                state = .idle
                observer.audioManagerDidStopRecording(self, maxLimitedReached: maxLimitReached)
            }
        }
    }
}
