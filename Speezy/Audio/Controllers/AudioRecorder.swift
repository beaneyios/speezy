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
    
    static let recordingThreshhold: TimeInterval = 120.0
    
    let item: AudioItem
    
    var recordingUrl: URL {
        getDocumentsDirectory().appendingPathComponent(
            "\(item.id)_recording.\(AudioConstants.fileExtension)"
        )
    }
    
    init(item: AudioItem) {
        self.item = item
        self.totalTime = item.duration
    }
    
    func record() {
        
        //Prevent sleep function after 45sec - will be enabled again after record
        UIApplication.shared.isIdleTimerDisabled = true
        
        if item.duration >= Self.recordingThreshhold {
            self.delegate?.audioRecorder(
                self,
                didFinishRecordingWithCompletedItem: self.item,
                maxLimitReached: true
            )
            
            return
        }
        
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
        let audioFilename = getDocumentsDirectory().appendingPathComponent("\(item.id)_recording.\(AudioConstants.fileExtension)")
        let settings = [
            AVFormatIDKey: AudioConstants.audioFormatKey,
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
                        
            recordingTimer = Timer.scheduledTimer(
                withTimeInterval: stepDuration,
                repeats: true
            ) { [weak self] (timer) in
                                
                guard let self = self else {
                    return
                }
                
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
    
    func cancelRecording() {
        // We don't want any callbacks being made here.
        // We just want to cancel the recording and remove any
        // remnants of it. So we set the delegate to nil to stop any
        // post-recording processing.
        audioRecorder?.delegate = nil
        audioRecorder?.stop()
        recordingTimer?.invalidate()
        recordingTimer = nil
        
        FileManager.default.deleteExistingURL(recordingUrl)
        
        //Prevent sleep function after 45sec - This is the enable after record
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        let currentFile = item.fileUrl
        let outputURL = item.fileUrl
        
        AudioFileCombiner.combineAudioFiles(
            audioURLs: [currentFile, recordingUrl],
            outputURL: outputURL
        ) { (url) in
            FileManager.default.deleteExistingURL(self.recordingUrl)
            self.delegate?.audioRecorder(
                self,
                didFinishRecordingWithCompletedItem: self.item,
                maxLimitReached: self.item.duration >= Self.recordingThreshhold
            )
        }
        
        //Prevent sleep function after 45sec - This is the enable after record
        UIApplication.shared.isIdleTimerDisabled = false
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
