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
    private(set) var hasUnsavedChanges = false
    private(set) var item: AudioItem
    private(set) var originalItem: AudioItem
    private(set) var currentImageAttachment: UIImage?
    
    var noTitleSet: Bool {
        item.title == ""
    }
    
    var state: AudioState {
        stateManager.state
    }
    
    private(set) var stateManager: AudioStateManager
    private var audioPlayer: AudioPlayer?
    private var audioRecorder: AudioRecorder?
    private var audioCropper: AudioCropper?
    private var audioCutter: AudioCutter?
    private var transcriptionJobManager: TranscriptionJobManager?
    private var transcriptManager: TranscriptManager
    private let audioAttachmentManager = AudioAttachmentManager()
    private let audioSavingManager = AudioSavingManager()
        
    init(item: AudioItem) {
        self.originalItem = item
        self.item = item.withStagingPath()        
        self.transcriptManager = TranscriptManager(audioItemId: item.id)
        self.stateManager = AudioStateManager()
        
        //Karl addedd
        UIApplication.shared.isIdleTimerDisabled = true
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
        audioSavingManager.discard(item: item, originalItem: originalItem) {
            self.markAsClean()
            completion()
        }
    }
    
    func toggleDirtiness() {
        hasUnsavedChanges = AudioItemChangeManager.itemHasUnsavedChanges(item)
    }
    
    func markAsDirty() {
        hasUnsavedChanges = true
        AudioItemChangeManager.storeUnsavedChange(for: item)
    }
    
    func markAsClean() {
        hasUnsavedChanges = false
        AudioItemChangeManager.removeUnsavedChange(for: item)
    }
    
    private func saveItem(completion: @escaping (AudioItem) -> Void) {
        let newItem = audioSavingManager.saveItem(
            item: item,
            originalItem: originalItem
        )
        markAsClean()
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
        self.item = item.withUpdatedTitle(title)
        markAsDirty()
    }
    
    func addTag(title: String) {
        self.item = item.addingTag(withTitle: title)
        markAsDirty()
    }
    
    func deleteTag(tag: Tag) {
        self.item = item.removingTag(tag: tag)
        markAsDirty()
    }
    
    func setImageAttachment(_ attachment: UIImage?) {
        currentImageAttachment = attachment
        markAsDirty()
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
    
    func audioRecorder(
        _ recorder: AudioRecorder,
        didRecordBarWithPower power: Float,
        stepDuration: TimeInterval,
        totalDuration: TimeInterval
    ) {
        stateManager.performRecordingAction(
            action: .showRecordingProgressed(
                power: power,
                stepDuration: stepDuration,
                totalDuration: totalDuration
            )
        )
    }
    
    func audioRecorder(
        _ recorder: AudioRecorder,
        didFinishRecordingWithCompletedItem item: AudioItem,
        maxLimitReached: Bool
    ) {
        self.item = item
        
        stateManager.performRecordingAction(
            action: .showRecordingStopped(item, maxLimitReached: maxLimitReached)
        )
        
        markAsDirty()
    }
}

// MARK: Playback
extension AudioManager: AudioPlayerDelegate {
    var currentItem: AudioItem {
        audioCropper?.croppedItem ?? audioCutter?.stagedCutItem ?? item
    }
    
    var startOffset: TimeInterval {
        audioCropper?.cropFrom ?? audioCutter?.cropFrom ?? 0.0
    }
    
    var duration: TimeInterval {
        item.duration
    }
    
    private var currentPlaybackTime: TimeInterval {
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
        if audioPlayer == nil {
            regeneratePlayer(withItem: currentItem)
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
        if audioPlayer == nil {
            print("Regenerating player")
            regeneratePlayer(withItem: currentItem)
        }
        
        let seekTime = item.duration * Double(percentage)
        
        audioPlayer?.seek(to: seekTime - startOffset)
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
    
    func audioPlayer(
        _ player: AudioPlayer,
        progressedPlaybackWithTime time: TimeInterval,
        seekActive: Bool
    ) {
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
        stateManager.performPlaybackAction(action: .showPlaybackStopped(item))
    }
    
    private func regeneratePlayer(withItem item: AudioItem) {
        audioPlayer = AudioPlayer(item: item)
        audioPlayer?.delegate = self
    }
}

// MARK: Crop/Cut crossover
extension AudioManager {
    var hasActiveEdit: Bool {
        hasActiveCrop || hasActiveCut
    }
    
    func applyEdit() {
        if audioCropper != nil {
            applyCrop()
        } else {
            applyCut()
        }
    }
    
    func cancelEdit() {
        if audioCropper != nil {
            cancelCrop()
        } else if audioCutter != nil {
            cancelCut()
        }
    }
    
    func edit(
        from: TimeInterval,
        to: TimeInterval
    ) {
        if audioCropper != nil {
            crop(from: from, to: to)
        } else if audioCutter != nil {
            cut(from: from, to: to)
        }
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
    
    func addCropperObserver(_ observer: AudioCropperObserver) {
        stateManager.addCropperObserver(observer)
    }
    
    func removeCropperObserver(_ observer: AudioCropperObserver) {
        stateManager.removeCropperObserver(observer)
    }
    
    func toggleCrop() {
        startCropping()
    }
    
    func startCropping() {
        audioCropper = AudioCropper(item: item)
        audioCropper?.delegate = self
        stateManager.performCroppingAction(action: .showCrop(item))
    }
        
    func crop(
        from: TimeInterval,
        to: TimeInterval
    ) {
        audioCropper?.crop(from: from, to: to)
    }
    
    func leftCropHandleMoved(to percentage: CGFloat) {
        stateManager.performCroppingAction(
            action: .leftHandleMoved(percentage: percentage)
        )
    }
    
    func rightCropHandleMoved(to percentage: CGFloat) {
        stateManager.performCroppingAction(
            action: .rightHandleMoved(percentage: percentage)
        )
    }
    
    func applyCrop() {
        audioCropper?.applyCrop()
    }
    
    func cancelCrop() {
        stop()
        audioCropper?.cancelCrop()
    }
    
    func audioCropper(
        _ cropper: AudioCropper,
        didAdjustCroppedItem item: AudioItem
    ) {
        regeneratePlayer(withItem: currentItem)
        stateManager.performCroppingAction(action: .showCropAdjusted(item))
    }
    
    func audioCropper(
        _ cropper: AudioCropper,
        didApplyCroppedItem item: AudioItem
    ) {
        stateManager.performCroppingAction(action: .showCropFinished(item))
        audioCropper = nil
        markAsDirty()
        regeneratePlayer(withItem: currentItem)
    }
    
    func audioCropper(
        _ cropper: AudioCropper,
        didCancelCropReturningToItem item: AudioItem
    ) {
        stateManager.performCroppingAction(action: .showCropCancelled(item))
        audioCropper = nil
    }
}

// MARK: CUTTING
extension AudioManager: AudioCutterDelegate {
    var isCutting: Bool {
        audioCutter != nil
    }
    
    var canCut: Bool {
        currentItem.duration > 3.0
    }
    
    var hasActiveCut: Bool {
        guard let cutItemDuration = audioCutter?.cutItem?.duration else {
            return false
        }
        
        return cutItemDuration != item.duration
    }
    
    func addCutterObserver(_ observer: AudioCutterObserver) {
        stateManager.addCutterObserver(observer)
    }
    
    func removeCutterObserver(_ observer: AudioCutterObserver) {
        stateManager.removeCutterObserver(observer)
    }
    
    func cut(from: TimeInterval, to: TimeInterval) {
        audioCutter?.cut(audioItem: item, from: from, to: to)
    }
    
    func cut(timeRanges: [CMTimeRange]) {
        if audioCutter == nil {
            regenerateCutter()
        }
        
        audioCutter?.cut(audioItem: item, timeRanges: timeRanges)
    }
    
    func applyCut() {
        guard let audioCutter = self.audioCutter else {
            assertionFailure("Audio cutter should not be nil")
            return
        }
        
        audioCutter.applyCut()
    }
    
    func toggleCut() {
        startCutting()
    }
    
    func cancelCut() {
        stop()
        audioCutter?.cancelCut()
    }
    
    func startCutting() {
        regenerateCutter()
        stateManager.performCuttingAction(action: .showCut(item))
    }
    
    // DELEGATES
    func audioCutter(_ cutter: AudioCutter, didAdjustCutItem item: AudioItem) {
        regeneratePlayer(withItem: currentItem)
        stateManager.performCuttingAction(action: .showCutAdjusted(item))
    }
    
    func audioCutter(_ cutter: AudioCutter, didApplyCutItem item: AudioItem, from: TimeInterval, to: TimeInterval) {
        stateManager.performCuttingAction(action: .showCutFinished(item: item, from: from, to: to))
        audioCutter = nil
        markAsDirty()
        regeneratePlayer(withItem: currentItem)
    }
    
    func audioCutter(_ cutter: AudioCutter, didCancelCutReturningToItem item: AudioItem) {
        stateManager.performCuttingAction(action: .showCutCancelled(item))
        audioCutter = nil
        regeneratePlayer(withItem: currentItem)
    }
    
    private func regenerateCutter() {
        audioCutter = AudioCutter(item: item)
        audioCutter?.delegate = self
    }
}

// MARK: Transcription jobs
extension AudioManager: TranscriptionJobManagerDelegate {
    func addTranscriptionObserver(_ observer: TranscriptionJobObserver) {
        stateManager.addTranscriptionObserver(observer)
    }
    
    func removeTranscriptionObserver(_ observer: TranscriptionJobObserver) {
        stateManager.removeTranscriptionObserver(observer)
    }
    
    func startTranscriptionJob() {
        createTranscriptionJobManagerIfNoneExists()
        transcriptionJobManager?.createTranscriptionJob(
            audioId: item.id,
            url: item.url
        )
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
    
    func transcriptionJobManager(
        _ manager: TranscriptionJobManager,
        didFinishTranscribingWithAudioItemId id: String,
        transcript: Transcript
    ) {
        updateTranscript(transcript)
        if id == item.id {
            markAsDirty()
            
            stateManager.performTranscriptionAction(
                action: .transcriptionComplete(
                    transcript: transcript,
                    audioId: id
                )
            )
        }
    }
    
    func transcriptionJobManager(
        _ manager: TranscriptionJobManager,
        didQueueItemWithId id: String
    ) {
        if id == item.id {
            stateManager.performTranscriptionAction(
                action: .transcriptionQueued(audioId: id)
            )
        }
    }
    
    private func createTranscriptionJobManagerIfNoneExists() {
        if transcriptionJobManager == nil {
            transcriptionJobManager = TranscriptionJobManager(
                transcriber: SpeezySpeechTranscriber()
            )
            transcriptionJobManager?.delegate = self
        }
    }
}

// MARK: Transcript editing
extension AudioManager: TranscriptManagerDelegate {
    var numberOfWordsInTranscript: Int {
        transcriptManager.numberOfWords
    }
    
    var transcriptExists: Bool {
        transcriptManager.transcriptExists
    }
    
    func addTranscriptObserver(_ observer: TranscriptObserver) {
        stateManager.addTranscriptObserver(observer)
    }
    
    func removeTranscriptObserver(_ observer: TranscriptObserver) {
        stateManager.removeTranscriptObserver(observer)
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
    
    func adjustTranscript(forCutRange from: TimeInterval, to: TimeInterval) {
        transcriptManager.adjustTranscript(
            forCutOperationFromStartPoint: from,
            end: to
        )
    }
    
    func transcriptManager(
        _ manager: TranscriptManager,
        didFinishEditingTranscript transcript: Transcript
    ) {
        markAsDirty()
        stateManager.performTranscriptAction(
            action: .finishedEditingTranscript(
                transcript: transcript,
                audioId: item.id
            )
        )
    }
    
    func transcriptManager(
        _ manager: TranscriptManager,
        shouldCutItemWithRanges ranges: [CMTimeRange]
    ) {
        cut(timeRanges: ranges)
        transcriptManager.updateTranscriptRemovingSelectedWords()
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
}
