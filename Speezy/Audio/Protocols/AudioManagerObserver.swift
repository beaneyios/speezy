//
//  AudioManagerObserver.swift
//  Speezy
//
//  Created by Matt Beaney on 14/07/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import UIKit

protocol AudioManagerObserver: class {
    func audioManager(_ manager: AudioManager, didStartPlaying item: AudioItem)
    func audioManager(_ manager: AudioManager, didPausePlaybackOf item: AudioItem)
    func audioManager(_ manager: AudioManager, didStopPlaying item: AudioItem)
    func audioManager(_ manager: AudioManager, progressedWithTime time: TimeInterval, seekActive: Bool)
    
    func audioManager(_ manager: AudioManager, didStartCroppingItem item: AudioItem, kind: CropKind)
    func audioManager(_ manager: AudioManager, didAdjustCropOnItem item: AudioItem)
    func audioManager(_ manager: AudioManager, didFinishCroppingItem item: AudioItem)
    func audioManager(_ manager: AudioManager, didMoveLeftCropHandleTo percentage: CGFloat)
    func audioManager(_ manager: AudioManager, didMoveRightCropHandleTo percentage: CGFloat)
    func audioManagerDidCancelCropping(_ manager: AudioManager)
    
    func audioManagerDidStartRecording(_ manager: AudioManager)
    func audioManager(_ manager: AudioManager, didRecordBarWithPower decibel: Float, stepDuration: TimeInterval, totalDuration: TimeInterval)
    func audioManagerProcessingRecording(_ manager: AudioManager)
    func audioManagerDidStopRecording(_ manager: AudioManager, maxLimitedReached: Bool)
}
