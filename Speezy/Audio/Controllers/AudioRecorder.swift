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
    
    let item: AudioItem
    
    init(item: AudioItem) {
        self.item = item
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
        let audioFilename = getDocumentsDirectory().appendingPathComponent("recording_\(item.id).m4a")
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.max.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.delegate = self
            audioRecorder?.record()
            delegate?.audioRecorderDidStartRecording(self)
                        
            recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { (timer) in
                guard let recorder = self.audioRecorder else {
                    assertionFailure("Somehow recorder is nil.")
                    return
                }

                recorder.updateMeters()
                let power = recorder.averagePower(forChannel: 0)
                self.delegate?.audioRecorder(self, didRecordBarWithPower: power, duration: 0.1)
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
        let newRecording = getDocumentsDirectory().appendingPathComponent("recording_\(item.id).m4a")
        let currentFile = item.url
        let outputURL = item.url
        
        AudioEditor.combineAudioFiles(audioURLs: [currentFile, newRecording], outputURL: outputURL) { (url) in
            FileManager.default.deleteExistingURL(newRecording)
            self.delegate?.audioRecorder(self, didFinishRecordingWithCompletedItem: self.item)
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
    func audioRecorder(_ recorder: AudioRecorder, didRecordBarWithPower power: Float, duration: TimeInterval)
    func audioRecorder(_ recorder: AudioRecorder, didFinishRecordingWithCompletedItem item: AudioItem)
}
