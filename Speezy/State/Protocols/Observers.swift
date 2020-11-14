//
//  AudioManagerObserver.swift
//  Speezy
//
//  Created by Matt Beaney on 14/07/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import UIKit

protocol AudioPlayerObserver: AnyObject {
    func playBackBegan(on item: AudioItem)
    func playbackPaused(on item: AudioItem)
    func playbackStopped(on item: AudioItem)
    func playbackProgressed(
        withTime time: TimeInterval,
        seekActive: Bool,
        onItem item: AudioItem,
        startOffset: TimeInterval
    )
}

protocol AudioRecorderObserver: AnyObject {
    func recordingBegan()
    func recordedBar(
        withPower decibel: Float,
        stepDuration: TimeInterval,
        totalDuration: TimeInterval
    )
    func recordingProcessing()
    func recordingStopped(maxLimitedReached: Bool)
}

protocol AudioCropperObserver: AnyObject {
    func audioManager(_ manager: AudioManager, didStartCroppingItem item: AudioItem, kind: CropKind)
    func audioManager(_ manager: AudioManager, didAdjustCropOnItem item: AudioItem)
    func audioManager(_ manager: AudioManager, didFinishCroppingItem item: AudioItem)
    func audioManager(_ manager: AudioManager, didMoveLeftCropHandleTo percentage: CGFloat)
    func audioManager(_ manager: AudioManager, didMoveRightCropHandleTo percentage: CGFloat)
    func audioManagerDidCancelCropping(_ manager: AudioManager)
}

protocol TranscriptionJobObserver: AnyObject {
    func audioManager(
        _ manager: AudioManager,
        didFinishTranscribingWithAudioItemId id: String,
        transcript: Transcript
    )
    
    func transcriptionJobManager(
        _ manager: AudioManager,
        didQueueTranscriptionJobWithAudioItemId: String
    )
}

protocol TranscriptObserver: AnyObject {
    func audioManager(
        _ manager: AudioManager,
        didFinishEditingTranscript transcript: Transcript
    )
}
