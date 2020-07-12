//
//  VideoGenerator.swift
//  Speezy
//
//  Created by Matt Beaney on 11/07/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import Foundation
import AVKit

class AudioEditor {
    func trim(
        fileURL: URL,
        startTime: Double,
        stopTime: Double,
        finished: @escaping (URL) -> Void
    ) {
        
        let asset = AVAsset(url: fileURL)
        let compatiblePresets = AVAssetExportSession.exportPresets(compatibleWith: asset)
        
        guard compatiblePresets.contains(AVAssetExportPresetMediumQuality) else {
            return
        }
        
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
            return
        }
        
        guard let outputURL = self.outputURL(for: "output.m4a") else {
            return
        }
        
        deleteExistingOutputFile("output.m4a")
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = AVFileType.m4a
        
        let start: CMTime = CMTimeMakeWithSeconds(startTime, preferredTimescale: asset.duration.timescale)
        let stop: CMTime = CMTimeMakeWithSeconds(stopTime, preferredTimescale: asset.duration.timescale)
        let range: CMTimeRange = CMTimeRangeFromTimeToTime(start: start, end: stop)
        exportSession.timeRange = range
        
        exportSession.exportAsynchronously(completionHandler: {
            
            switch exportSession.status {
            case .failed:
                print("Export failed: \(exportSession.error!.localizedDescription)")
            case .cancelled:
                print("Export canceled")
            default:
                print("Successfully trimmed audio")
                DispatchQueue.main.async(execute: {
                    finished(outputURL)
                })
            }
        })
    }
    
    private func outputURL(for name: String) -> URL? {
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
    
    private func deleteExistingOutputFile(_ name: String) {
        let fileManager = FileManager.default
        do {
            let documentDirectory = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor:nil, create:false)
            let fileURL = documentDirectory.appendingPathComponent(name)
            try fileManager.removeItem(at: fileURL)
        } catch {
            print(error)
        }
    }
}
