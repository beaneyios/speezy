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
    func audioCutter(_ cropper: AudioCutter, didApplyCutItem item: AudioItem, from: TimeInterval, to: TimeInterval)
    func audioCutter(
        _ cropper: AudioCutter,
        didCancelCutReturningToItem item: AudioItem
    )
}

class AudioCutter: AudioCropping {
    private let item: AudioItem
    private(set) var cutItem: AudioItem?
    private(set) var stagedCutItem: AudioItem?
    
    private(set) var cropFrom: TimeInterval = 0.0
    private(set) var cropTo: TimeInterval = 0.0
    
    private let cutExtension = "_cut.\(AudioConstants.fileExtension)"
    let cropExtension = "_cropped.\(AudioConstants.fileExtension)"
    
    weak var delegate: AudioCutterDelegate?
    
    init(item: AudioItem) {
        self.item = item
    }
    
    func cut(audioItem: AudioItem, timeRanges: [CMTimeRange]) {
        cut(audioItem: audioItem, timeRanges: timeRanges) { (url) in
            let cutItem = self.item.withPath(path: url)
            self.cutItem = cutItem
            self.applyCut()
        }
    }
    
    func cut(audioItem: AudioItem, from: TimeInterval, to: TimeInterval) {
        cropFrom = from
        cropTo = to
        
        crop(audioItem: audioItem, startTime: from, stopTime: to) { (croppedOutputPath) in
            let croppedItem = self.item.withPath(path: croppedOutputPath)
            self.stagedCutItem = croppedItem
            
            self.cut(audioItem: audioItem, from: from, to: to) { (cutOutputPath) in
                let cutItem = self.item.withPath(path: cutOutputPath)                
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
        
        if let stagedPath = self.stagedCutItem?.path {
            FileManager.default.deleteExistingFile(with: stagedPath)
        }
        
        FileManager.default.deleteExistingFile(with: self.item.path)
        FileManager.default.renameFile(
            from: cutItem.path,
            to: item.path
        )
        delegate?.audioCutter(self, didApplyCutItem: item, from: cropFrom, to: cropTo)
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
            url: audioItem.fileUrl,
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
            url: audioItem.fileUrl,
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
            let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A),
            let outputURL = FileManager.default.documentsURL(with: outputPath)
        else {
            return
        }
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = AudioConstants.outputFileType
        
        exportSession.exportAsynchronously() {
            switch exportSession.status {
            case .failed:
                assertionFailure("Export failed: " + String(describing: exportSession.error?.localizedDescription))
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
