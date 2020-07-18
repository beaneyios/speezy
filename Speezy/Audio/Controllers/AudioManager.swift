//
//  AudioManager.swift
//  Speezy
//
//  Created by Matt Beaney on 14/07/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import Foundation
import AVKit

class AudioManager: NSObject {
    private(set) var item: AudioItem
    private(set) var trimmedItem: AudioItem?
    
    private(set) var state = State.idle {
        didSet { stateDidChange() }
    }
    
    var duration: TimeInterval {
        let asset = AVAsset(url: item.url)
        let duration = CMTimeGetSeconds(asset.duration)
        return TimeInterval(duration)
    }
    
    private var observations = [ObjectIdentifier : Observation]()
    
    private var player: AVAudioPlayer?
    private var playbackTimer: Timer?
    
    private var recordingSession: AVAudioSession?
    private var audioRecorder: AVAudioRecorder?
    private var recordingTimer: Timer?
    
    init(item: AudioItem) {
        self.item = item
        self.player = try? AVAudioPlayer(contentsOf: item.url)
        
        super.init()
        self.player?.delegate = self
    }
    
    private func stateDidChange() {
        observations.forEach {
            guard let observer = $0.value.observer else {
                observations.removeValue(forKey: $0.key)
                return
            }

            switch state {
            case .idle:
                observer.audioPlayerDidStop(self)
            case .playing(let item):
                observer.audioPlayer(self, didStartPlaying: item)
            case .paused(let item):
                observer.audioPlayer(self, didPausePlaybackOf: item)
            }
        }
    }
}

// MARK: Recording
extension AudioManager: AVAudioRecorderDelegate {
    func record() {
        do {
            recordingSession = AVAudioSession.sharedInstance()
            try recordingSession?.setCategory(.playAndRecord, mode: .default)
            try recordingSession?.setActive(true, options: [])
            recordingSession?.requestRecordPermission({ (allowed) in
                DispatchQueue.main.async {
                    if allowed {
                        self.startRecording()
                    } else {
                        
                    }
                }
            })
        } catch {
            
        }
    }
    
    func stopRecording() {
        audioRecorder?.stop()
        recordingTimer?.invalidate()
        recordingTimer = nil
    }
    
    private func startRecording() {
        let audioFilename = self.getDocumentsDirectory().appendingPathComponent("recording.m4a")
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.delegate = self
            audioRecorder?.record()
            
            self.observations.forEach {
                guard let observer = $0.value.observer else {
                    self.observations.removeValue(forKey: $0.key)
                    return
                }

                observer.audioPlayerDidStartRecording(self)
            }
            
            self.recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { (timer) in
                guard let recorder = self.audioRecorder else {
                    assertionFailure("Somehow recorder is nil.")
                    return
                }

                recorder.updateMeters()
                let power = recorder.averagePower(forChannel: 0)

                self.observations.forEach {
                    guard let observer = $0.value.observer else {
                        self.observations.removeValue(forKey: $0.key)
                        return
                    }

                    observer.audioPlayer(self, didRecordBarWithPower: power, duration: recorder.currentTime)
                }
            }
        } catch {
            
        }
    }
    
    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
}

// MARK: Playback
extension AudioManager {
    func play() {
        state = .playing(item)
        player?.play()
        startPlaybackTimer()
    }

    func pause() {
        switch state {
        case .idle, .paused:
            break
        case .playing(let item):
            state = .paused(item)
            player?.pause()
        }
        
        playbackTimer?.invalidate()
    }

    func stop() {
        state = .idle
        playbackTimer?.invalidate()
    }
    
    private func startPlaybackTimer() {
        self.playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { (timer) in
            guard let player = self.player else {
                assertionFailure("Player nil for some reason")
                return
            }
            
            self.observations.forEach {
                guard let observer = $0.value.observer else {
                    self.observations.removeValue(forKey: $0.key)
                    return
                }
                
                observer.audioPlayer(self, progressedWithTime: player.currentTime)
            }
        }
    }
}

// MARK: Editing
extension AudioManager {
    func trim(from: TimeInterval, to: TimeInterval) {
        AudioEditor.trim(fileURL: item.url, startTime: from, stopTime: to) { (url) in
            let trimmedItem = AudioItem(url: url)
            self.trimmedItem = trimmedItem
            
            self.player = try? AVAudioPlayer(contentsOf: url)
            
            self.observations.forEach {
                guard let observer = $0.value.observer else {
                    self.observations.removeValue(forKey: $0.key)
                    return
                }
                
                observer.audioPlayer(self, didCreateTrimmedItem: trimmedItem)
            }
        }
    }
    
    func applyTrim() {
        guard let trimmedItem = self.trimmedItem else {
            return
        }
        
        self.item = trimmedItem
        
        self.observations.forEach {
            guard let observer = $0.value.observer else {
                self.observations.removeValue(forKey: $0.key)
                return
            }
            
            observer.audioPlayer(self, didApplyTrimmedItem: trimmedItem)
        }
    }
    
    func cancelTrim() {
        trimmedItem = nil
        
        self.observations.forEach {
            guard let observer = $0.value.observer else {
                self.observations.removeValue(forKey: $0.key)
                return
            }
            
            observer.audioPlayerDidCancelTrim(self)
        }
    }
}

extension AudioManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        playbackTimer?.invalidate()
        playbackTimer = nil
        state = .idle
        stateDidChange()
    }
}

extension AudioManager {
    func togglePlayback() {
        switch state {
        case .playing:
            self.pause()
        case .paused, .idle:
            self.play()
        }
    }
}

extension AudioManager {
    func addObserver(_ observer: AudioManagerObserver) {
        let id = ObjectIdentifier(observer)
        observations[id] = Observation(observer: observer)
    }

    func removeObserver(_ observer: AudioManagerObserver) {
        let id = ObjectIdentifier(observer)
        observations.removeValue(forKey: id)
    }
}

extension AudioManager {
    enum State {
        case idle
        case playing(AudioItem)
        case paused(AudioItem)
    }
    
    struct Observation {
        weak var observer: AudioManagerObserver?
    }
}
