//
//  AudioManagerObserver.swift
//  Speezy
//
//  Created by Matt Beaney on 14/07/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import Foundation

protocol AudioManagerObserver: class {
    func audioManager(_ player: AudioManager, didStartPlaying item: AudioItem)
    func audioManager(_ player: AudioManager, didPausePlaybackOf item: AudioItem)
    func audioManager(_ player: AudioManager, didStopPlaying item: AudioItem)
    func audioManager(_ player: AudioManager, progressedWithTime time: TimeInterval)
    
    func audioManager(_ player: AudioManager, didStartCroppingItem item: AudioItem)
    func audioManager(_ player: AudioManager, didAdjustCropOnItem item: AudioItem)
    func audioManager(_ player: AudioManager, didFinishCroppingItem item: AudioItem)
    func audioManager(_ player: AudioManager, didConfirmCropOnItem item: AudioItem)
    func audioManagerDidCancelCropping(_ player: AudioManager)
    
    func audioManagerDidStartRecording(_ player: AudioManager)
    func audioManager(_ player: AudioManager, didRecordBarWithPower decibel: Float, duration: TimeInterval)
    func audioManagerProcessingRecording(_ player: AudioManager)
    func audioManagerDidStopRecording(_ player: AudioManager)
}
