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

typealias AudioManagerObservationManaging = TranscriptionJobObservationManaging &
                                            TranscriptObservationManaging &
                                            CropperObservationManaging

class AudioManager: NSObject, AudioManagerObservationManaging {
    private(set) var item: AudioItem
    private(set) var originalItem: AudioItem
    private(set) var hasUnsavedChanges: Bool = false
    
    private(set) var stateManager: AudioStateManager
    
    private var firstRecord = true
    var noTitleSet: Bool {
        item.title == ""
    }
    
    var state: AudioState {
        stateManager.state
    }
    
    var recorderObservatons = [ObjectIdentifier : AudioRecorderObservation]()
    var cropperObservatons = [ObjectIdentifier : AudioCropperObservation]()
    var transcriptionJobObservations = [ObjectIdentifier : TranscriptionJobObservation]()
    var transcriptObservations = [ObjectIdentifier : TranscriptObservation]()
    
    private var audioPlayer: AudioPlayer?
    private var audioRecorder: AudioRecorder?
    private var audioCropper: AudioCropper?
    private var transcriptionJobManager: TranscriptionJobManager?
    private var transcriptManager: TranscriptManager
    private let audioAttachmentManager = AudioAttachmentManager()
    
    private(set) var currentImageAttachment: UIImage?
    
    init(item: AudioItem) {
        self.originalItem = item
        
        self.item = AudioItem(
            id: item.id,
            path: "\(item.id)_staging.wav",
            title: item.title,
            date: item.date,
            tags: item.tags,
            url: item._url
        )
        
        self.transcriptManager = TranscriptManager(audioItemId: item.id)
        self.stateManager = AudioStateManager()
    }
    
    func save(saveAttachment: Bool, completion: @escaping (AudioItem) -> Void) {
        if saveAttachment {
            commitImageAttachment {
                self.saveItem(completion: completion)
            }
        } else {
            saveItem(completion: completion)
        }
    }
    
    func discard(completion: @escaping () -> Void) {
        FileManager.default.deleteExistingURL(item.url)
        FileManager.default.copy(original: originalItem.url, to: item.url)
        completion()
    }
    
    private func saveItem(completion: @escaping (AudioItem) -> Void) {
        FileManager.default.deleteExistingFile(with: originalItem.path)
        FileManager.default.copy(original: item.url, to: originalItem.url)
        
        let newItem = AudioItem(
            id: item.id,
            path: "\(item.id).wav",
            title: item.title,
            date: item.date,
            tags: item.tags
        )
        
        AudioStorage.saveItem(newItem)
        hasUnsavedChanges = false
        transcriptManager.saveTranscript()
        completion(newItem)
    }
    
    private func commitImageAttachment(completion: @escaping () -> Void) {
        audioAttachmentManager.storeAttachment(
            currentImageAttachment,
            forItem: item,
            completion: completion
        )
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
        hasUnsavedChanges = true
    }
    
    func addTag(title: String) {
        
        let tagTitles = title.split(separator: ",")
        
        let tags = tagTitles.map {
            Tag(id: UUID().uuidString, title: String($0))
        }
                
        let newItem = AudioItem(
            id: item.id,
            path: item.path,
            title: item.title,
            date: item.date,
            tags: item.tags + tags
        )
        
        self.item = newItem
        
        hasUnsavedChanges = true
    }
    
    func deleteTag(tag: Tag) {
        let newTags = item.tags.filter {
            $0.id != tag.id
        }
        
        let newItem = AudioItem(
            id: item.id,
            path: item.path,
            title: item.title,
            date: item.date,
            tags: newTags
        )
        
        self.item = newItem
        
        hasUnsavedChanges = true
    }
    
    func setImageAttachment(_ attachment: UIImage?) {
        currentImageAttachment = attachment
        
        hasUnsavedChanges = true
    }
    
    func fetchImageAttachment(completion: @escaping (UIImage?) -> Void) {
        audioAttachmentManager.fetchAttachment(forItem: item) { (image) in
            self.currentImageAttachment = image
            completion(image)
        }
    }
}

// MARK: Recording
extension AudioManager: AudioRecorderDelegate {
    var hasRecorded: Bool {
        item.duration > 0
    }
    
    func addRecorderObserver(_ observer: AudioRecorderObserver) {
        stateManager.addRecorderObserver(observer)
    }
    
    func removeRecorderObserver(_ observer: AudioRecorderObserver) {
        stateManager.removeRecorderObserver(observer)
    }
    
    func toggleRecording() {
        switch stateManager.state {
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
        stateManager.performRecordingAction(action: .showRecordingStarted(item))
    }
    
    func audioRecorderDidStartProcessingRecording(_ recorder: AudioRecorder) {
        stateManager.performRecordingAction(action: .showRecordingProcessing(item))
    }
    
    func audioRecorder(_ recorder: AudioRecorder, didRecordBarWithPower power: Float, stepDuration: TimeInterval, totalDuration: TimeInterval) {
        stateManager.performRecordingAction(
            action: .showRecordingProgressed(
                power: power,
                stepDuration: stepDuration,
                totalDuration: totalDuration
            )
        )
    }
    
    func audioRecorder(_ recorder: AudioRecorder, didFinishRecordingWithCompletedItem item: AudioItem, maxLimitReached: Bool) {
        self.item = item
        
        stateManager.performRecordingAction(
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
    
    var startOffset: TimeInterval {
        audioCropper?.cropFrom ?? 0.0
    }
    
    var duration: TimeInterval {
        item.duration
    }
    
    var currentPlaybackTime: TimeInterval {
        audioPlayer?.currentPlaybackTime ?? 0.0
    }
    
    func addPlaybackObserver(_ observer: AudioPlayerObserver) {
        stateManager.addPlaybackObserver(observer)
    }
    
    func removePlaybackObserver(_ observer: AudioPlayerObserver) {
        stateManager.removePlaybackObserver(observer)
    }
    
    func togglePlayback() {
        switch stateManager.state {
        case .startedPlayback:
            pause()
        default:
            play()
        }
    }
    
    func play() {
        if stateManager.state.shouldRegeneratePlayer == true {
            audioPlayer = AudioPlayer(item: currentItem)
            audioPlayer?.delegate = self
        }
        
        audioPlayer?.play()
    }
    
    func pause() {
        switch stateManager.state {
        case .startedPlayback:
            audioPlayer?.pause()
        default:
            break
        }
    }
    
    func seek(to percentage: Float) {
        if audioPlayer == nil || isCropping {
            audioPlayer = AudioPlayer(item: currentItem)
            audioPlayer?.delegate = self
            stateManager.state = .pausedPlayback(currentItem)
        }
        
        audioPlayer?.seek(to: percentage)
    }

    func stop() {
        audioPlayer?.stop()
    }
    
    func audioPlayerDidBeginPlayback(_ player: AudioPlayer) {
        stateManager.performPlaybackAction(action: .showPlaybackStarted(item))
    }
    
    func audioPlayerDidPausePlayback(_ player: AudioPlayer) {
        stateManager.performPlaybackAction(action: .showPlaybackPaused(item))
    }
    
    func audioPlayer(_ player: AudioPlayer, progressedPlaybackWithTime time: TimeInterval, seekActive: Bool) {
        stateManager.performPlaybackAction(
            action: .showPlaybackProgressed(
                time,
                seekActive: seekActive,
                item: item,
                timeOffset: startOffset
            )
        )
    }
    
    func audioPlayerDidStopPlayback(_ player: AudioPlayer) {
        audioPlayer = nil
        stateManager.performPlaybackAction(action: .showPlaybackStopped(item))
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
    
    func toggleCut() {
        startCutting()
    }
    
    func startCropping() {
        audioCropper = AudioCropper(item: item)
        audioCropper?.delegate = self
        performCroppingAction(action: .showCrop(item, .trim))
    }
    
    func startCutting() {
        audioCropper = AudioCropper(item: item)
        audioCropper?.delegate = self
        performCroppingAction(action: .showCrop(item, .cut))
    }
    
    func crop(from: TimeInterval, to: TimeInterval, cropKind: CropKind) {
        audioCropper?.crop(from: from, to: to, cropKind: cropKind)
    }
    
    func cut(timeRanges: [CMTimeRange]) {
        audioCropper = AudioCropper(item: item)
        audioCropper?.delegate = self
        audioCropper?.cut(audioItem: self.item, timeRanges: timeRanges)
    }
    
    func leftCropHandleMoved(to percentage: CGFloat) {
        cropperObservatons.forEach {
            $0.value.observer?.leftCropHandle(movedToPercentage: percentage)
        }
    }
    
    func rightCropHandleMoved(to percentage: CGFloat) {
        cropperObservatons.forEach {
            $0.value.observer?.rightCropHandle(movedToPercentage: percentage)
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
        performCroppingAction(action: .showCropAdjusted(item))
    }
    
    func audioCropper(_ cropper: AudioCropper, didApplyCroppedItem item: AudioItem, kind: CropKind) {
        
        FileManager.default.deleteExistingFile(with: self.item.path)
        FileManager.default.renameFile(from: "\(item.id)\(kind.pathExtension)", to: self.item.path)
        
        performCroppingAction(action: .showCropFinished(item))
        audioCropper = nil
        
        hasUnsavedChanges = true
    }
    
    func audioCropper(_ cropper: AudioCropper, didCancelCropReturningToItem item: AudioItem) {
        self.item = item
        performCroppingAction(action: .showCropCancelled(item))
        audioCropper = nil
    }
}

extension AudioManager {
    func performCroppingAction(action: CropAction) {
        cropperObservatons.forEach {
            guard let observer = $0.value.observer else {
                recorderObservatons.removeValue(forKey: $0.key)
                return
            }
            
            switch action {
            case .showCrop(let item, let kind):
                stateManager.state = .cropping
                observer.croppingStarted(onItem: item, kind: kind)
                
            case .showCropAdjusted(let item):
                observer.cropRangeAdjusted(onItem: item)
                
            case .showCropCancelled:
                stateManager.state = .idle
                observer.croppingCancelled()
                
            case .showCropFinished(let item):
                stateManager.state = .idle
                observer.croppingFinished(onItem: item)
            }
        }
    }
    
    func performTranscriptionAction(action: TranscriptionJobAction) {
        transcriptionJobObservations.forEach {
            guard let observer = $0.value.observer else {
                transcriptionJobObservations.removeValue(forKey: $0.key)
                return
            }
            
            switch action {
            case let .transcriptionComplete(transcript, audioId):
                
                break
            case let .transcriptionQueued(audioId):
                break
            }
        }
    }
    
    func performTranscriptAction(action: TranscriptAction) {
        transcriptObservations.forEach {
            guard let observer = $0.value.observer else {
                transcriptObservations.removeValue(forKey: $0.key)
                return
            }
            
            switch action {
            case let .finishedEditingTranscript(transcript, audioId):
                break
            }
        }
    }
}

// MARK: Transcription jobs
extension AudioManager: TranscriptionJobManagerDelegate {
    func startTranscriptionJob() {
        createTranscriptionJobManagerIfNoneExists()
        transcriptionJobManager?.createTranscriptionJob(audioId: item.id, url: item.url)
    }
    
    func checkTranscriptionJobs() {
        createTranscriptionJobManagerIfNoneExists()
        transcriptionJobManager?.startCheckJobs()
    }
    
    func stopTranscriptionChecks() {
        transcriptionJobManager?.stopChecks()
    }
    
    var transcriptionJobExists: Bool {
        transcriptionJobManager?.jobExists(id: item.id) ?? false
    }
    
    func transcriptionJobManager(_ manager: TranscriptionJobManager, didFinishTranscribingWithAudioItemId id: String, transcript: Transcript) {
        updateTranscript(transcript)
        if id == item.id {
            hasUnsavedChanges = true
            
            performTranscriptionAction(
                action: .transcriptionComplete(
                    transcript: transcript,
                    audioId: id
                )
            )
        }
    }
    
    func transcriptionJobManager(_ manager: TranscriptionJobManager, didQueueItemWithId id: String) {
        if id == item.id {
            performTranscriptionAction(action: .transcriptionQueued(audioId: id))
        }
    }
    
    private func createTranscriptionJobManagerIfNoneExists() {
        if transcriptionJobManager == nil {
            transcriptionJobManager = TranscriptionJobManager(transcriber: SpeezySpeechTranscriber())
            transcriptionJobManager?.delegate = self
        }
    }
}

// MARK: Transcript editing
extension AudioManager: TranscriptManagerDelegate {
    func transcriptManager(_ manager: TranscriptManager, didFinishEditingTranscript transcript: Transcript) {
        hasUnsavedChanges = true
        performTranscriptAction(
            action: .finishedEditingTranscript(transcript: transcript, audioId: item.id)
        )
    }
    
    func transcriptManager(_ manager: TranscriptManager, shouldCutItemWithRanges ranges: [CMTimeRange]) {
        cut(timeRanges: ranges)
        transcriptManager.updateTranscriptRemovingSelectedWords()
    }
    
    var numberOfWordsInTranscript: Int {
        transcriptManager.numberOfWords
    }
    
    var transcriptExists: Bool {
        transcriptManager.transcriptExists
    }
    
    func transcribedWord(for index: Int) -> Word? {
        transcriptManager.word(for: index)
    }
    
    func transcribedWordIsSelected(word: Word) -> Bool {
        transcriptManager.isSelected(word: word)
    }
    
    func selectTranscribedWord(at indexPath: IndexPath) {
        transcriptManager.toggleSelection(at: indexPath)
    }
    
    func currentPlayingTranscribedWord(at time: TimeInterval) -> Word? {
        transcriptManager.currentPlayingWord(at: time)
    }
    
    func currentPlayingTranscribedWordIndex(at time: TimeInterval) -> Int? {
        transcriptManager.currentPlayingWordIndex(at: time)
    }
    
    func updateTranscript(_ transcript: Transcript) {
        transcriptManager.updateTranscript(transcript)
    }
    
    func removeTranscribedUhms() {
        transcriptManager.delegate = self
        transcriptManager.removeUhms()
    }
    
    func removeSelectedTranscribedWords() {
        transcriptManager.delegate = self
        transcriptManager.removeSelectedWords()
    }
}
