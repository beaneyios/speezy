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

protocol AudioCutterObserver: AnyObject {
    func cuttingStarted(onItem item: AudioItem)
    func cutRangeAdjusted(onItem item: AudioItem)
    func cuttingFinished(onItem item: AudioItem, from: TimeInterval, to: TimeInterval)
    func leftCropHandle(movedToPercentage percentage: CGFloat)
    func rightCropHandle(movedToPercentage percentage: CGFloat)
    func cuttingCancelled()
}

protocol AudioCropperObserver: AnyObject {
    func croppingStarted(onItem item: AudioItem)
    func cropRangeAdjusted(onItem item: AudioItem)
    func croppingFinished(onItem item: AudioItem)
    func leftCropHandle(movedToPercentage percentage: CGFloat)
    func rightCropHandle(movedToPercentage percentage: CGFloat)
    func croppingCancelled()
}

protocol TranscriptionJobObserver: AnyObject {
    func transcriptionFinished(on itemWithId: String, transcript: Transcript)
    func transcriptionQueued(on itemId: String)
}

protocol TranscriptObserver: AnyObject {
    func finishedEditingTranscript(transcript: Transcript)
}
