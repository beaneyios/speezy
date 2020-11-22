//
//  AudioCutter.swift
//  Speezy
//
//  Created by Matt Beaney on 21/11/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import Foundation
import AVKit

protocol AudioCutterDelegate: AnyObject {
    func audioCutter(_ cropper: AudioCutter, didAdjustCutItem item: AudioItem)
    func audioCutter(_ cropper: AudioCutter, didApplyCutItem item: AudioItem)
    func audioCutter(
        _ cropper: AudioCutter,
        didCancelCutReturningToItem item: AudioItem
    )
}

class AudioCutter: AudioCropping {
    private let item: AudioItem
    private(set) var cutItem: AudioItem?
    private(set) var stagedCutItem: AudioItem?
    
    private let cutExtension = "_cut.wav"
    let cropExtension = "_cropped.wav"
    
    weak var delegate: AudioCutterDelegate?
    
    init(item: AudioItem) {
        self.item = item
    }
    
    func cut(audioItem: AudioItem, timeRanges: [CMTimeRange]) {
        cut(audioItem: audioItem, timeRanges: timeRanges) { (url) in
            let cutItem = AudioItem(
                id: self.item.id,
                path: url,
                title: self.item.title,
                date: self.item.date,
                tags: self.item.tags
            )
            
            self.cutItem = cutItem
            self.delegate?.audioCutter(self, didApplyCutItem: cutItem)
        }
    }
    
    func cut(audioItem: AudioItem, from: TimeInterval, to: TimeInterval) {
        crop(audioItem: audioItem, startTime: from, stopTime: to) { (croppedOutputPath) in
            let croppedItem = AudioItem(
                id: self.item.id,
                path: croppedOutputPath,
                title: self.item.title,
                date: self.item.date,
                tags: self.item.tags
            )
            
            self.stagedCutItem = croppedItem
            
            self.cut(audioItem: audioItem, from: from, to: to) { (cutOutputPath) in
                let cutItem = AudioItem(
                    id: self.item.id,
                    path: cutOutputPath,
                    title: self.item.title,
                    date: self.item.date,
                    tags: self.item.tags
                )
                
                self.cutItem = cutItem
                self.delegate?.audioCutter(self, didAdjustCutItem: cutItem)
            }
        }
    }
    
    func applyCut() {
        guard let cutItem = self.cutItem else {
            delegate?.audioCutter(self, didCancelCutReturningToItem: item)
            return
        }
        
        FileManager.default.deleteExistingFile(with: self.item.path)
        FileManager.default.renameFile(
            from: "\(item.id)\(cutExtension)",
            to: item.path
        )
        delegate?.audioCutter(self, didApplyCutItem: cutItem)
    }
    
    func cancelCut() {
        delegate?.audioCutter(self, didCancelCutReturningToItem: item)
    }
}

extension AudioCutter {
    func cut(
        audioItem: AudioItem,
        from startTime: Double,
        to endTime: Double,
        finished: @escaping (String) -> Void
    ) {
        let asset = AVURLAsset(
            url: audioItem.url,
            options: [AVURLAssetPreferPreciseDurationAndTimingKey: true]
        )
        
        let outputPath = "\(audioItem.id)\(cutExtension)"
        FileManager.default.deleteExistingFile(with: outputPath)
        
        do {
            let composition: AVMutableComposition = AVMutableComposition()
            try composition.insertTimeRange(
                CMTimeRangeMake(
                    start: CMTime.zero,
                    duration: asset.duration
                ),
                of: asset,
                at: CMTime.zero
            )
            
            let startTime = CMTime(seconds: startTime, preferredTimescale: 100)
            let endTime = CMTime(seconds: endTime, preferredTimescale: 100)
            composition.removeTimeRange(
                CMTimeRangeFromTimeToTime(
                    start: startTime,
                    end: endTime
                )
            )
            
            performCutExport(
                audioItem: audioItem,
                outputPath: outputPath,
                composition: composition,
                finished: finished
            )
        } catch {
            
        }
    }
    
    func cut(
        audioItem: AudioItem,
        timeRanges: [CMTimeRange],
        finished: @escaping (String) -> Void
    ) {
        let asset = AVURLAsset(
            url: audioItem.url,
            options: [AVURLAssetPreferPreciseDurationAndTimingKey: true]
        )
        let outputPath = "\(audioItem.id)\(cutExtension)"
        FileManager.default.deleteExistingFile(with: outputPath)
        
        do {
            let composition: AVMutableComposition = AVMutableComposition()
            try composition.insertTimeRange(
                CMTimeRangeMake(
                    start: CMTime.zero,
                    duration: asset.duration
                ),
                of: asset,
                at: CMTime.zero
            )
            
            timeRanges.reversed().forEach {
                composition.removeTimeRange($0)
            }
            
            performCutExport(
                audioItem: audioItem,
                outputPath: outputPath,
                composition: composition,
                finished: finished
            )
        } catch {
            assertionFailure("\(error)")
        }
    }
    
    private func performCutExport(
        audioItem: AudioItem,
        outputPath: String,
        composition: AVMutableComposition,
        finished: @escaping (String) -> Void
    ) {
        guard
            let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetPassthrough),
            let outputURL = FileManager.default.documentsURL(with: outputPath)
        else {
            return
        }
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = AVFileType.wav
        
        exportSession.exportAsynchronously() {
            switch exportSession.status {
            case .failed:
                assertionFailure("Export failed: \(exportSession.error?.localizedDescription)")
            case .cancelled:
                assertionFailure("Export canceled")
            default:
                DispatchQueue.main.async(execute: {
                    finished(outputPath)
                })
            }
        }
    }
}
