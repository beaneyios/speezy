//
//  FileInserter.swift
//  Speezy
//
//  Created by Matt Beaney on 02/06/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation
import AVKit

protocol FileInserterDelegate: AnyObject {
    func fileInserter(_ inserter: FileInserter, didMergeItemsIntoItem item: AudioItem)
}

class FileInserter {
    private let item: AudioItem
    private let preRecordedItem: AudioItem
    private let insertExtension = "_insert.\(AudioConstants.fileExtension)"
    
    weak var delegate: FileInserterDelegate?
    
    init(item: AudioItem, preRecordedItem: AudioItem) {
        self.item = item
        self.preRecordedItem = preRecordedItem
    }
    
    func insert(at time: TimeInterval) {
        let asset = AVURLAsset(
            url: item.fileUrl,
            options: [AVURLAssetPreferPreciseDurationAndTimingKey: true]
        )
        
        let preRecordedAsset = AVURLAsset(
            url: preRecordedItem.fileUrl,
            options: [AVURLAssetPreferPreciseDurationAndTimingKey: true]
        )
        
        do {
            let composition: AVMutableComposition = AVMutableComposition()
            
            // Insert the original file
            try composition.insertTimeRange(
                CMTimeRange(
                    start: CMTime.zero,
                    duration: asset.duration
                ),
                of: asset,
                at: CMTime.zero
            )
            
            // Now insert the pre-recorded sound
            try composition.insertTimeRange(
                CMTimeRange(
                    start: CMTime.zero,
                    duration: preRecordedAsset.duration
                ),
                of: preRecordedAsset,
                at: CMTime(seconds: time, preferredTimescale: 100)
            )
            
            // Now export.
            guard
                let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A)
            else {
                assertionFailure("Can't create export session")
                return
            }
            
            FileManager.default.deleteExistingFile(with: item.path)
            exportSession.outputFileType = AudioConstants.outputFileType
            let outputURL = FileManager.default.documentsURL(with: item.path)
            exportSession.outputURL = outputURL
            exportSession.exportAsynchronously {
                switch exportSession.status {
                case .failed:
                    assertionFailure("Export failed: \(exportSession.error)")
                case .cancelled:
                    assertionFailure("Export canceled")
                default:
                    self.delegate?.fileInserter(self, didMergeItemsIntoItem: self.item)
                }
            }
        } catch {
            
        }
    }
}

// Might need later.
//            // Add the first portion of the original file.
//            try composition.insertTimeRange(
//                CMTimeRangeMake(
//                    start: CMTime.zero,
//                    duration: CMTime(seconds: time, preferredTimescale: 100)
//                ),
//                of: asset,
//                at: CMTime.zero
//            )
//
//            // Add the new file
//            try composition.insertTimeRange(
//                CMTimeRangeMake(
//                    start: CMTime.zero,
//                    duration: preRecordedAsset.duration
//                ),
//                of: preRecordedAsset,
//                at: CMTime(seconds: time, preferredTimescale: 100)
//            )
//
//            // Add the second portion of the original file
//            let remainingTime = asset.duration.seconds - time
//            try composition.insertTimeRange(
//                CMTimeRangeMake(
//                    start: CMTime(seconds: time, preferredTimescale: 100),
//                    duration: CMTime(seconds: remainingTime, preferredTimescale: 100)
//                ),
//                of: asset,
//                at: time +
//            )
