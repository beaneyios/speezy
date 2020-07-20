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
    private(set) var originalItem: AudioItem
    private(set) var trimmedItem: AudioItem?
    
    private(set) var state = State.idle
    
    var duration: TimeInterval {
        let asset = AVAsset(url: item.url)
        let duration = CMTimeGetSeconds(asset.duration)
        return TimeInterval(duration)
    }
    
    var currentPlaybackTime: TimeInterval {
        player?.currentTime ?? 0.0
    }
    
    private var observations = [ObjectIdentifier : Observation]()
    
    private var player: AVAudioPlayer?
    private var playbackTimer: Timer?
    
    private var recordingSession: AVAudioSession?
    private var audioRecorder: AVAudioRecorder?
    private var recordingTimer: Timer?
    
    init(item: AudioItem) {
        self.originalItem = item
        self.item = item
    }
    
    private func stateDidChange() {
        observations.forEach {
            guard let observer = $0.value.observer else {
                observations.removeValue(forKey: $0.key)
                return
            }

            switch state {
            case .idle:
                break
                
            case .trimmingStarted(let item):
                observer.audioPlayer(self, didCreateTrimmedItem: item)
            case .trimmingCancelled:
                observer.audioPlayerDidCancelTrim(self)
            case .trimmingApplied(let item):
                observer.audioPlayer(self, didApplyTrimmedItem: item)
                
            case .stoppedPlayback:
                observer.audioPlayerDidStop(self)
            case .startedPlayback(let item):
                observer.audioPlayer(self, didStartPlaying: item)
            case .pausedPlayback(let item):
                observer.audioPlayer(self, didPausePlaybackOf: item)
            
            case .startedRecording:
                observer.audioPlayerDidStartRecording(self)
            case .stoppedRecording:
                observer.audioPlayerDidStopRecording(self)
            case .processingRecording:
                observer.audioPlayerProcessingRecording(self)
            }
        }
    }
}

// MARK: Recording
extension AudioManager: AVAudioRecorderDelegate {
    func toggleRecording() {
        switch state {
        case .startedRecording:
            stopRecording()
        default:
            startRecording()
        }
    }
    
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
    
    private func startRecording() {
        let audioFilename = self.getDocumentsDirectory().appendingPathComponent("recording_\(item.id).m4a")
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
            
            self.recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { (timer) in
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

                    observer.audioPlayer(self, didRecordBarWithPower: power, duration: 0.1)
                }
            }
        } catch {
            
        }
        
        state = .startedRecording(item)
        stateDidChange()
    }
    
    func stopRecording() {
        state = .processingRecording(item)
        stateDidChange()
        audioRecorder?.stop()
        recordingTimer?.invalidate()
        recordingTimer = nil
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        let newRecording = getDocumentsDirectory().appendingPathComponent("recording_\(item.id).m4a")
        let currentFile = item.url
        let outputURL = item.url
        
        AudioEditor.combineAudioFiles(audioURLs: [currentFile, newRecording], outputURL: outputURL) { (url) in
            self.item = AudioItem(id: self.item.id, url: url)
            self.state = .stoppedRecording(self.item)
            self.stateDidChange()
        }
    }
    
    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
}

// MARK: Playback
extension AudioManager: AVAudioPlayerDelegate {
    func togglePlayback() {
        switch state {
        case .startedPlayback:
            pause()
        default:
            play()
        }
    }
    
    func play() {
        if state.isPaused == false {
            player = try? AVAudioPlayer(contentsOf: item.url)
            player?.delegate = self
        }
        
        state = .startedPlayback(item)
        player?.play()
        startPlaybackTimer()
        stateDidChange()
    }
    
    func pause() {
        switch state {
        case let .startedPlayback(item):
            state = .pausedPlayback(item)
            player?.pause()
            playbackTimer?.invalidate()
            stateDidChange()
        default:
            break
        }
    }

    func stop() {
        state = .stoppedPlayback
        playbackTimer?.invalidate()
        stateDidChange()
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        playbackTimer?.invalidate()
        playbackTimer = nil
        state = .stoppedPlayback
        stateDidChange()
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
            let trimmedItem = AudioItem(id: self.item.id, url: url)
            self.trimmedItem = trimmedItem
            
            self.player = try? AVAudioPlayer(contentsOf: url)
            self.state = .trimmingStarted(trimmedItem)
            self.stateDidChange()
        }
    }
    
    func applyTrim() {
        guard let trimmedItem = self.trimmedItem else {
            return
        }
        
        self.item = trimmedItem
        self.state = .trimmingApplied(trimmedItem)
        self.stateDidChange()
    }
    
    func cancelTrim() {
        trimmedItem = nil
        state = .trimmingCancelled(self.item)
        stateDidChange()
    }
}

// MARK: State management
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
        
        case trimmingStarted(AudioItem)
        case trimmingCancelled(AudioItem)
        case trimmingApplied(AudioItem)
        
        case stoppedPlayback
        case startedPlayback(AudioItem)
        case pausedPlayback(AudioItem)
        
        case startedRecording(AudioItem)
        case processingRecording(AudioItem)
        case stoppedRecording(AudioItem)
        
        var isPaused: Bool {
            if case State.pausedPlayback = self {
                return true
            } else {
                return false
            }
        }
    }
    
    struct Observation {
        weak var observer: AudioManagerObserver?
    }
}
