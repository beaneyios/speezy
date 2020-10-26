//
//  AudioRecorder.swift
//  Speezy
//
//  Created by Matt Beaney on 20/07/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import Foundation
import AVKit

class AudioRecorder: NSObject, AVAudioRecorderDelegate {
    private var recordingSession: AVAudioSession?
    private var audioRecorder: AVAudioRecorder?
    private var recordingTimer: Timer?
    
    weak var delegate: AudioRecorderDelegate?
    private var totalTime: TimeInterval = 0.0
    
    static let recordingThreshhold: TimeInterval = 120
    
    let item: AudioItem
    
    init(item: AudioItem) {
        self.item = item
        self.totalTime = item.duration
    }
    
    func record() {
        recordingSession = AVAudioSession.sharedInstance()
        recordingSession?.prepareForRecording()
        recordingSession?.requestRecordPermission({ (allowed) in
            DispatchQueue.main.async {
                if allowed {
                    self.startRecording()
                } else {
                    // TODO: Handle not allowed.
                }
            }
        })
    }
    
    private func startRecording() {
        let audioFilename = getDocumentsDirectory().appendingPathComponent("\(item.id)_recording.wav")
        let settings = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.max.rawValue
        ]
        
        do {
            let stepDuration = 0.1
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.delegate = self
            audioRecorder?.record()
            delegate?.audioRecorderDidStartRecording(self)
                        
            recordingTimer = Timer.scheduledTimer(withTimeInterval: stepDuration, repeats: true) { (timer) in
                guard let recorder = self.audioRecorder else {
                    assertionFailure("Somehow recorder is nil.")
                    return
                }
                
                recorder.updateMeters()
                let power = recorder.averagePower(forChannel: 0)
                self.delegate?.audioRecorder(self, didRecordBarWithPower: power, stepDuration: stepDuration, totalDuration: self.totalTime)
                
                if self.totalTime > Self.recordingThreshhold {
                    self.stopRecording()
                }
                
                self.totalTime += stepDuration
            }
        } catch {
            
        }
    }
    
    func stopRecording() {
        delegate?.audioRecorderDidStartProcessingRecording(self)
        audioRecorder?.stop()
        recordingTimer?.invalidate()
        recordingTimer = nil
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        let newRecording = getDocumentsDirectory().appendingPathComponent("\(item.id)_recording.wav")
        let currentFile = item.url
        let outputURL = item.url
        
        AudioFileCombiner.combineAudioFiles(audioURLs: [currentFile, newRecording], outputURL: outputURL) { (url) in
            FileManager.default.deleteExistingURL(newRecording)
            self.delegate?.audioRecorder(
                self,
                didFinishRecordingWithCompletedItem: self.item,
                maxLimitReached: self.item.duration >= Self.recordingThreshhold
            )
        }
    }
    
    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
}

protocol AudioRecorderDelegate: AnyObject {
    func audioRecorderDidStartRecording(_ recorder: AudioRecorder)
    func audioRecorderDidStartProcessingRecording(_ recorder: AudioRecorder)
    func audioRecorder(_ recorder: AudioRecorder, didRecordBarWithPower power: Float, stepDuration: TimeInterval, totalDuration: TimeInterval)
    func audioRecorder(_ recorder: AudioRecorder, didFinishRecordingWithCompletedItem item: AudioItem, maxLimitReached: Bool)
}
