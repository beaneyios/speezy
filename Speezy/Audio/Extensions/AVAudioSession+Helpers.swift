//
//  AVAudioSession+Helpers.swift
//  Speezy
//
//  Created by Matt Beaney on 16/08/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import AVKit

extension AVAudioSession {
    var isHeadphonesConnected: Bool {
        return !currentRoute.outputs.filter {
            $0.portType == AVAudioSession.Port.headphones || $0.portType == AVAudioSession.Port.bluetoothHFP || $0.portType == AVAudioSession.Port.bluetoothA2DP
            
        }.isEmpty
    }
    
    func selectCorrectOutput() throws {
        do {
            if isHeadphonesConnected {
                try overrideOutputAudioPort(.none)
            } else {
                try overrideOutputAudioPort(.speaker)
            }
        } catch {
            print(error)
        }
    }
    
    func prepareForPlayback() {
        do {
            try setCategory(.playback, mode: .spokenAudio)
            try selectCorrectOutput()
            try setActive(true, options: [])
        } catch {
            assertionFailure("Something went wrong configuring playback")
        }
    }
    
    func prepareForRecording() {
        do {
            try setCategory(.playAndRecord, mode: .spokenAudio)
            try setActive(true, options: [])
        } catch {
            assertionFailure("Something went wrong configuring recording")
        }
    }
}
