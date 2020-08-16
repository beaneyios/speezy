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
    private let originalItem: AudioItem
    private(set) var croppedItem: AudioItem?
    
    private(set) var cropFrom: TimeInterval?
    private(set) var cropTo: TimeInterval?
    
    var hasActiveCrop: Bool {
        let duration = TimeInterval(CMTimeGetSeconds(AVAsset(url: originalItem.url).duration))
        
        if
            let cropFrom = cropFrom,
            let cropTo = cropTo,
            cropFrom > 0 || cropTo < duration
        {
            return true
        }
        
        return false
    }
    
    weak var delegate: AudioCropperDelegate?
    
    init(originalItem: AudioItem) {
        self.originalItem = originalItem
    }
    
    func crop(from: TimeInterval, to: TimeInterval) {
        cropFrom = from
        cropTo = to
        crop(audioItem: originalItem, startTime: from, stopTime: to) { (path) in
            let croppedItem = AudioItem(
                id: self.originalItem.id,
                path: path,
                title: self.originalItem.title,
                date: self.originalItem.date,
                tags: self.originalItem.tags
            )
            self.croppedItem = croppedItem
            self.delegate?.audioCropper(self, didAdjustCroppedItem: croppedItem)
        }
    }
    
    func applyCrop() {
        guard let croppedItem = self.croppedItem else {
            delegate?.audioCropper(self, didCancelCropReturningToItem: originalItem)
            return
        }
        
        delegate?.audioCropper(self, didApplyCroppedItem: croppedItem)
    }
    
    func cancelCrop() {
        delegate?.audioCropper(self, didCancelCropReturningToItem: originalItem)
    }
}

extension AudioCropper {
    func crop(
        audioItem: AudioItem,
        startTime: Double,
        stopTime: Double,
        finished: @escaping (String) -> Void
    ) {
        
        let asset = AVAsset(url: audioItem.url)
        let compatiblePresets = AVAssetExportSession.exportPresets(compatibleWith: asset)
        
        guard
            compatiblePresets.contains(AVAssetExportPresetAppleM4A),
            let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A),
            let outputURL = FileManager.default.documentsURL(with: "\(audioItem.id)_cropped.m4a")
        else {
            return
        }
        
        FileManager.default.deleteExistingFile(with: "\(audioItem.id)_cropped.m4a")
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = AVFileType.m4a
        
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
                print("Successfully cropped audio")
                DispatchQueue.main.async(execute: {
                    finished("\(audioItem.id)_cropped.m4a")
                })
            }
        }
    }
}
