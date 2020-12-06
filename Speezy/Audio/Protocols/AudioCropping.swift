//
//  AudioCropping.swift
//  Speezy
//
//  Created by Matt Beaney on 22/11/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import Foundation
import AVKit

protocol AudioCropping {
    var cropExtension: String { get }
    
    func crop(
        audioItem: AudioItem,
        startTime: Double,
        stopTime: Double,
        finished: @escaping (String) -> Void
    )
}

extension AudioCropping {
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
