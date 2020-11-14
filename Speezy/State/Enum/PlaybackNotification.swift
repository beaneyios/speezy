//
//  PlaybackNotification.swift
//  Speezy
//
//  Created by Matt Beaney on 14/11/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import Foundation

enum PlaybackAction {
    case showPlaybackStopped(AudioItem)
    case showPlaybackStarted(AudioItem)
    case showPlaybackPaused(AudioItem)
    case showPlaybackProgressed(
            TimeInterval,
            seekActive: Bool,
            item: AudioItem,
            timeOffset: TimeInterval
         )
}
