//
//  AudioStateManager.swift
//  Speezy
//
//  Created by Matt Beaney on 14/11/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import Foundation

typealias AudioStateManagerObservationManaging =    PlayerObservationManaging &
                                                    RecorderObservationManaging &
                                                    TranscriptionJobObservationManaging &
                                                    TranscriptObservationManaging &
                                                    CropperObservationManaging

class AudioStateManager: AudioStateManagerObservationManaging {
    var state = AudioState.idle
    
    var playerObservatons = [ObjectIdentifier : AudioPlayerObservation]()
    var recorderObservatons = [ObjectIdentifier : AudioRecorderObservation]()
    var cropperObservatons = [ObjectIdentifier : AudioCropperObservation]()
    var transcriptionJobObservations = [ObjectIdentifier : TranscriptionJobObservation]()
    var transcriptObservations = [ObjectIdentifier : TranscriptObservation]()
    
    func performPlaybackAction(action: PlaybackAction) {
        playerObservatons.forEach {
            guard let observer = $0.value.observer else {
                recorderObservatons.removeValue(forKey: $0.key)
                return
            }
            
            switch action {
            case .showPlaybackStopped(let item):
                state = .stoppedPlayback(item)
                observer.playbackStopped(on: item)
                
            case .showPlaybackStarted(let item):
                state = .startedPlayback(item)
                observer.playBackBegan(on: item)
                
            case .showPlaybackPaused(let item):
                state = .pausedPlayback(item)
                observer.playbackPaused(on: item)
            case let .showPlaybackProgressed(time, seekActive, item, startOffset):
                observer.playbackProgressed(
                    withTime: time,
                    seekActive: seekActive,
                    onItem: item,
                    startOffset: startOffset
                )
            }
        }
    }
    
    func performRecordingAction(action: RecordAction) {
        recorderObservatons.forEach {
            guard let observer = $0.value.observer else {
                recorderObservatons.removeValue(forKey: $0.key)
                return
            }
            
            switch action {
            case .showRecordingStarted:
                state = .recording
                observer.recordingBegan()
            
            case let .showRecordingProgressed(power, stepDuration, totalDuration):
                observer.recordedBar(
                    withPower: power,
                    stepDuration: stepDuration,
                    totalDuration: totalDuration
                )
                
            case .showRecordingProcessing:
                observer.recordingProcessing()
                
            case let .showRecordingStopped(_, maxLimitReached):
                state = .idle
                observer.recordingStopped(maxLimitedReached: maxLimitReached)
            }
        }
    }
    
    func performCroppingAction(action: CropAction) {
        cropperObservatons.forEach {
            guard let observer = $0.value.observer else {
                recorderObservatons.removeValue(forKey: $0.key)
                return
            }
            
            switch action {
            case .showCrop(let item, let kind):
                state = .cropping
                observer.croppingStarted(onItem: item, kind: kind)
                
            case .showCropAdjusted(let item):
                observer.cropRangeAdjusted(onItem: item)
                
            case .showCropCancelled:
                state = .idle
                observer.croppingCancelled()
                
            case .showCropFinished(let item):
                state = .idle
                observer.croppingFinished(onItem: item)
                
            case .leftHandleMoved(let percentage):
                observer.leftCropHandle(movedToPercentage: percentage)
                
            case .rightHandleMoved(let percentage):
                observer.rightCropHandle(movedToPercentage: percentage)
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
                observer.transcriptionFinished(on: audioId, transcript: transcript)
            case let .transcriptionQueued(audioId):
                observer.transcriptionQueued(on: audioId)
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
            case let .finishedEditingTranscript(transcript, _):
                observer.finishedEditingTranscript(transcript: transcript)
            }
        }
    }
}
