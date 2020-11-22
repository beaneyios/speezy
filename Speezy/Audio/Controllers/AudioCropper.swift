//
//  AudioCropper.swift
//  Speezy
//
//  Created by Matt Beaney on 20/07/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import Foundation
import AVKit

protocol AudioCropperDelegate: AnyObject {
    func audioCropper(_ cropper: AudioCropper, didAdjustCroppedItem item: AudioItem)
    func audioCropper(_ cropper: AudioCropper, didApplyCroppedItem item: AudioItem)
    func audioCropper(_ cropper: AudioCropper, didCancelCropReturningToItem item: AudioItem)
}

class AudioCropper {
    private let item: AudioItem
    private(set) var croppedItem: AudioItem?
    private var cutItem: AudioItem?
    
    private let cropExtension = "_cropped.wav"
    
    private(set) var cropFrom: TimeInterval?
    private(set) var cropTo: TimeInterval?
    
    weak var delegate: AudioCropperDelegate?
    
    init(item: AudioItem) {
        self.item = item
    }
    
    func crop(from: TimeInterval, to: TimeInterval) {
        cropFrom = from
        cropTo = to
        
        crop(audioItem: item, startTime: from, stopTime: to) { (path) in
            let croppedItem = AudioItem(
                id: self.item.id,
                path: path,
                title: self.item.title,
                date: self.item.date,
                tags: self.item.tags
            )
            self.croppedItem = croppedItem
            self.delegate?.audioCropper(self, didAdjustCroppedItem: croppedItem)
        }
    }
    
    func applyCrop() {
        guard let croppedItem = self.croppedItem else {
            delegate?.audioCropper(self, didCancelCropReturningToItem: item)
            return
        }
        
        delegate?.audioCropper(self, didApplyCroppedItem: croppedItem)
    }
    
    func cancelCrop() {
        delegate?.audioCropper(self, didCancelCropReturningToItem: item)
    }
}

// MARK: Cropping private functions
extension AudioCropper {
    func crop(
        audioItem: AudioItem,
        startTime: Double,
        stopTime: Double,
        finished: @escaping (String) -> Void
    ) {
        let asset = AVAsset(url: audioItem.url)
        let outputPath = "\(audioItem.id)\(cropExtension)"
        
        guard
            let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetPassthrough),
            let outputURL = FileManager.default.documentsURL(with: outputPath)
        else {
            return
        }
        
        FileManager.default.deleteExistingFile(with: outputPath)
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = AVFileType.wav
        
        let start: CMTime = CMTimeMakeWithSeconds(startTime, preferredTimescale: asset.duration.timescale)
        let stop: CMTime = CMTimeMakeWithSeconds(stopTime, preferredTimescale: asset.duration.timescale)
        let range: CMTimeRange = CMTimeRangeFromTimeToTime(start: start, end: stop)
        exportSession.timeRange = range
        
        exportSession.exportAsynchronously() {
            switch exportSession.status {
            case .failed:
                print("Export failed: \(String(describing: exportSession.error?.localizedDescription))")
            case .cancelled:
                print("Export canceled")
            default:
                print("Successfully cropped audio")
                DispatchQueue.main.async(execute: {
                    finished(outputPath)
                })
            }
        }
    }
}
