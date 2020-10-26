//
//  ExperimentalDisfluencyDetection.swift
//  Speezy
//
//  Created by Matt Beaney on 08/10/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import Foundation
import AVKit

class ExperimentalDisfluencyDetection {
    var audioItem: AudioItem!
    var collectionView: UICollectionView!
    
    class AudioWord {
        var audioItem: AudioItem
        var startIndex: Int
        var totalLevels: [Float]
        var endIndex: Int!
        var levels: [Float] = []
        
        var startSeconds: TimeInterval!
        var endSeconds: TimeInterval!
        
        init(audioItem: AudioItem, startIndex: Int, totalLevels: [Float]) {
            self.audioItem = audioItem
            self.startIndex = startIndex
            self.totalLevels = totalLevels
        }
        
        func setEndIndex(_ index: Int) {
            self.endIndex = index
            
            let startIndexPercentage = Double(startIndex) / Double(totalLevels.count)
            let endIndexPercentage = Double(index) / Double(totalLevels.count)
            
            self.startSeconds = audioItem.duration * startIndexPercentage
            self.endSeconds = audioItem.duration * endIndexPercentage
        }
    }
    
    private func renderTranscription(transcript: Transcript) {
        AudioLevelGenerator.render(fromAudioItem: self.audioItem, targetSamplesPolicy: .custom(5000)) { (audioData) in
            DispatchQueue.main.async {
                
                var currentGroup: AudioWord? = nil
                var audioClips: [AudioWord] = []
                
                for (index, percentageLevel) in audioData.percentageLevels.enumerated() {
                    if (percentageLevel * 100) < 20 {
                        if let existingCurrentGroup = currentGroup {
                            existingCurrentGroup.setEndIndex(index - 1)
                            audioClips.append(existingCurrentGroup)
                            currentGroup = nil
                        }
                        
                        continue
                    }
                    
                    if let existingCurrentGroup = currentGroup, index == audioData.percentageLevels.count - 1 {
                        existingCurrentGroup.setEndIndex(index - 1)
                        audioClips.append(existingCurrentGroup)
                        currentGroup = nil
                        continue
                    }
                    
                    if let existingCurrentGroup = currentGroup {
                        existingCurrentGroup.levels.append(percentageLevel)
                    } else {
                        currentGroup = AudioWord(
                            audioItem: self.audioItem,
                            startIndex: index,
                            totalLevels: audioData.percentageLevels
                        )
                    }
                }
                
                
                audioClips = audioClips.filter { (audioWord) -> Bool in
                    self.audioClipContainsWord(audioWord: audioWord, words: transcript.words) == false
                }.filter {
                    if $0.startSeconds == $0.endSeconds || ($0.endSeconds - $0.startSeconds) < 0.5 {
                        return false
                    }
                    
                    return true
                }
                
                let sema = DispatchSemaphore(value: 0)
                audioClips.forEach {
                    if $0.startSeconds == $0.endSeconds || ($0.endSeconds - $0.startSeconds) < 0.5 {
                        return
                    }

                    self.crop(
                        name: "uhm-\($0.startIndex)",
                        url: self.audioItem.url,
                        startTime: $0.startSeconds,
                        stopTime: $0.endSeconds
                    ) { (path) in
                        print("New path: \(path)")
                        sema.signal()
                    }

                    sema.wait()
                }
                
                let trimWords = transcript.words.filter {
                    $0.text.contains("HESITATION")
                }
                
                self.cut(audioItem: self.audioItem, from: audioClips) { (path) in
                    print(path)
                }
                
                self.collectionView.reloadData()
            }
        }
    }
    
    private func audioClipContainsWord(audioWord: AudioWord, words: [Word]) -> Bool {
        words.contains { (word) -> Bool in
            word.timestamp.start >= audioWord.startSeconds && word.timestamp.end <= audioWord.endSeconds
        }
    }
    
    func cut(
            audioItem: AudioItem,
            from range: [AudioWord],
            finished: @escaping (String) -> Void
        ) {
            let asset = AVURLAsset(url: audioItem.url, options: [AVURLAssetPreferPreciseDurationAndTimingKey: true])
            let compatiblePresets = AVAssetExportSession.exportPresets(compatibleWith: asset)
                    
            FileManager.default.deleteExistingFile(with: "\(audioItem.id)\(CropKind.cut.pathExtension)")
            
            do {
                let composition: AVMutableComposition = AVMutableComposition()
                try composition.insertTimeRange( CMTimeRangeMake(start: CMTime.zero, duration: asset.duration), of: asset, at: CMTime.zero)
                
                range.reversed().forEach {
                    let startTime = CMTime(seconds: $0.startSeconds, preferredTimescale: 100)
                    let endTime = CMTime(seconds: $0.endSeconds, preferredTimescale: 100)
                    composition.removeTimeRange(CMTimeRangeFromTimeToTime(start: startTime, end: endTime))
                }
                
                guard
                    compatiblePresets.contains(AVAssetExportPresetPassthrough),
                    let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetPassthrough),
                    let outputURL = FileManager.default.documentsURL(with: "\(audioItem.id)\(CropKind.cut.pathExtension)")
                else {
                    return
                }
                
                exportSession.outputURL = outputURL
                exportSession.outputFileType = AVFileType.wav
                
                exportSession.exportAsynchronously() {
                    switch exportSession.status {
                    case .failed:
                        print("Export failed: \(exportSession.error?.localizedDescription)")
                    case .cancelled:
                        print("Export canceled")
                    default:
                        print("Successfully cut audio")
                        DispatchQueue.main.async(execute: {
                            finished("\test_cut.wav")
                        })
                    }
                }
            } catch {
                
            }
        }
    
    func crop(
        name: String,
        url: URL,
        startTime: Double,
        stopTime: Double,
        finished: @escaping (String) -> Void
    ) {
        
        let asset = AVURLAsset(url: url, options: [AVURLAssetPreferPreciseDurationAndTimingKey: true])
        let compatiblePresets = AVAssetExportSession.exportPresets(compatibleWith: asset)
        
        guard
            compatiblePresets.contains(AVAssetExportPresetPassthrough),
            let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetPassthrough),
            let outputURL = FileManager.default.documentsURL(with: "\(name).wav")
        else {
            return
        }
        
        FileManager.default.deleteExistingFile(with: "\(name).wav")
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = AVFileType.wav
        
        let start: CMTime = CMTimeMakeWithSeconds(startTime, preferredTimescale: asset.duration.timescale)
        let stop: CMTime = CMTimeMakeWithSeconds(stopTime, preferredTimescale: asset.duration.timescale)
        let range: CMTimeRange = CMTimeRangeFromTimeToTime(start: start, end: stop)
        exportSession.timeRange = range
        
        exportSession.exportAsynchronously() {
            switch exportSession.status {
            case .failed:
                print("Export failed: \(exportSession.error?.localizedDescription)")
            case .cancelled:
                print("Export canceled")
            default:
                finished("\(name).wav")
            }
        }
    }
}
