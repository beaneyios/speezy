//
//  RecordNotification.swift
//  Speezy
//
//  Created by Matt Beaney on 14/11/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import Foundation

enum RecordAction {
    case showRecordingStarted(AudioItem)
    case showRecordingProgressed(power: Float, stepDuration: TimeInterval, totalDuration: TimeInterval)
    case showRecordingProcessing(AudioItem)
    case showRecordingStopped(AudioItem, maxLimitReached: Bool)
}
