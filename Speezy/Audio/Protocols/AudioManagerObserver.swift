//
//  AudioManagerObserver.swift
//  Speezy
//
//  Created by Matt Beaney on 14/07/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import Foundation

protocol AudioManagerObserver: class {
    func audioPlayer(_ player: AudioManager, didStartPlaying item: AudioItem)
    func audioPlayer(_ player: AudioManager, didPausePlaybackOf item: AudioItem)
    func audioPlayerDidStop(_ player: AudioManager)
    func audioPlayer(_ player: AudioManager, progressedWithTime time: TimeInterval)
    func audioPlayer(_ player: AudioManager, didCreateTrimmedItem item: AudioItem)
}
