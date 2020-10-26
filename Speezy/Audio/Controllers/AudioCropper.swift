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
    func audioCropper(_ cropper: AudioCropper, didApplyCroppedItem item: AudioItem, kind: CropKind)
    func audioCropper(_ cropper: AudioCropper, didCancelCropReturningToItem item: AudioItem)
}

class AudioCropper {
    private let item: AudioItem
    private(set) var croppedItem: AudioItem?
    private var cutItem: AudioItem?
    
    private(set) var cropFrom: TimeInterval?
    private(set) var cropTo: TimeInterval?
    
    weak var delegate: AudioCropperDelegate?
    
    init(item: AudioItem) {
        self.item = item
    }
    
    func crop(from: TimeInterval, to: TimeInterval, cropKind: CropKind) {
        cropFrom = from
        cropTo = to
        
        switch cropKind {
        case .trim:
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
        case .cut:
            crop(audioItem: item, startTime: from, stopTime: to) { (path) in
                let croppedItem = AudioItem(
                    id: self.item.id,
                    path: path,
                    title: self.item.title,
                    date: self.item.date,
                    tags: self.item.tags
                )
                
                self.croppedItem = croppedItem
                
                self.cut(audioItem: self.item, from: from, to: to) { (path) in
                    let cutItem = AudioItem(
                        id: self.item.id,
                        path: path,
                        title: self.item.title,
                        date: self.item.date,
                        tags: self.item.tags
                    )
                    
                    self.cutItem = cutItem
                    self.delegate?.audioCropper(self, didAdjustCroppedItem: croppedItem)
                }
            }
            
        }
        
    }
    
    func applyCrop() {
        guard let croppedItem = self.croppedItem else {
            delegate?.audioCropper(self, didCancelCropReturningToItem: item)
            return
        }
        
        delegate?.audioCropper(self, didApplyCroppedItem: croppedItem, kind: cutItem != nil ? .cut : .trim)
    }
    
    func cancelCrop() {
        delegate?.audioCropper(self, didCancelCropReturningToItem: item)
    }
}

extension AudioCropper {
    func cut(
        audioItem: AudioItem,
        from startTime: Double,
        to endTime: Double,
        finished: @escaping (String) -> Void
    ) {
        let asset = AVURLAsset(url: audioItem.url, options: [AVURLAssetPreferPreciseDurationAndTimingKey: true])
        let compatiblePresets = AVAssetExportSession.exportPresets(compatibleWith: asset)
                
        FileManager.default.deleteExistingFile(with: "\(audioItem.id)\(CropKind.cut.pathExtension)")
        
        do {
            let composition: AVMutableComposition = AVMutableComposition()
            try composition.insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: asset.duration), of: asset, at: CMTime.zero)
            
            let startTime = CMTime(seconds: startTime, preferredTimescale: 100)
            let endTime = CMTime(seconds: endTime, preferredTimescale: 100)
            composition.removeTimeRange( CMTimeRangeFromTimeToTime(start: startTime, end: endTime))
            
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
                        finished("\(audioItem.id)_cut.wav")
                    })
                }
            }
        } catch {
            
        }
    }
    
    func crop(
        audioItem: AudioItem,
        startTime: Double,
        stopTime: Double,
        finished: @escaping (String) -> Void
    ) {
        
        let asset = AVAsset(url: audioItem.url)
        let compatiblePresets = AVAssetExportSession.exportPresets(compatibleWith: asset)
        
        guard
            compatiblePresets.contains(AVAssetExportPresetPassthrough),
            let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetPassthrough),
            let outputURL = FileManager.default.documentsURL(with: "\(audioItem.id)\(CropKind.trim.pathExtension)")
        else {
            return
        }
        
        FileManager.default.deleteExistingFile(with: "\(audioItem.id)\(CropKind.trim.pathExtension)")
        
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
                print("Successfully cropped audio")
                DispatchQueue.main.async(execute: {
                    finished("\(audioItem.id)\(CropKind.trim.pathExtension)")
                })
            }
        }
    }
}
