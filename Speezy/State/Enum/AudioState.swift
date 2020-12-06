//
//  AudioState.swift
//  Speezy
//
//  Created by Matt Beaney on 14/11/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import Foundation

enum AudioState {
    case idle

    case stoppedPlayback(AudioItem)
    case startedPlayback(AudioItem)
    case pausedPlayback(AudioItem)
    
    case cutting
    case cropping
    case recording
    
    var shouldRegeneratePlayer: Bool {
        switch self {
        case .pausedPlayback:
            return false
        default:
            return true
        }
    }
    
    var isInPlayback: Bool {
        switch self {
        case .startedPlayback, .pausedPlayback, .stoppedPlayback:
            return true
        default:
            return false
        }
    }
    
    var isRecording: Bool {
        switch self {
        case .recording:
            return true
        default:
            return false
        }
    }
}
