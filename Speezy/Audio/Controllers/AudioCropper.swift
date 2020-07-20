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
    func audioCropper(_ cropper: AudioCropper, didCreateCroppedItem item: AudioItem)
    func audioCropper(_ cropper: AudioCropper, didApplyCroppedItem item: AudioItem)
    func audioCropper(_ cropper: AudioCropper, didCancelCropReturningToItem item: AudioItem)
}

class AudioCropper {
    private let originalItem: AudioItem
    private(set) var croppedItem: AudioItem?
    
    weak var delegate: AudioCropperDelegate?
    
    init(originalItem: AudioItem) {
        self.originalItem = originalItem
    }
    
    func crop(from: TimeInterval, to: TimeInterval) {
        let url = originalItem.url
        crop(fileURL: url, startTime: from, stopTime: to) { (url) in
            let croppedItem = AudioItem(id: self.originalItem.id, url: url)
            self.croppedItem = croppedItem
            self.delegate?.audioCropper(self, didCreateCroppedItem: croppedItem)
        }
    }
    
    func applyCrop() {
        guard let croppedItem = self.croppedItem else {
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
        fileURL: URL,
        startTime: Double,
        stopTime: Double,
        finished: @escaping (URL) -> Void
    ) {
        
        let asset = AVAsset(url: fileURL)
        let compatiblePresets = AVAssetExportSession.exportPresets(compatibleWith: asset)
        
        guard
            compatiblePresets.contains(AVAssetExportPresetHighestQuality),
            let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A),
            let outputURL = outputURL(for: "output.m4a")
        else {
            return
        }
        
        deleteExistingOutputFile("output.m4a")
        
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
                    finished(outputURL)
                })
            }
        }
    }
    
    func deleteExistingOutputFile(_ name: String) {
        let fileManager = FileManager.default
        do {
            let documentDirectory = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor:nil, create:false)
            let fileURL = documentDirectory.appendingPathComponent(name)
            try fileManager.removeItem(at: fileURL)
        } catch {
            print(error)
        }
    }
    
    func outputURL(for name: String) -> URL? {
        let fileManager = FileManager.default
        do {
            let documentDirectory = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor:nil, create:false)
            let fileURL = documentDirectory.appendingPathComponent(name)
            return fileURL
        } catch {
            print(error)
        }
        
        return nil
    }
}
