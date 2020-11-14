//
//  AudioStateManager.swift
//  Speezy
//
//  Created by Matt Beaney on 14/11/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import Foundation

class AudioStateManager: AudioManagerObservationManaging {
    private(set) var state = AudioState.idle
    
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
            case let .showPlaybackProgressed(time, seekActive, item):
                observer.playbackProgressed(withTime: time, seekActive: seekActive, onItem: item)
            }
        }
    }
}
