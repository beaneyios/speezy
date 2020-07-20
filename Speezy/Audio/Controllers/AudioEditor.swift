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
    static func convertOriginalToSpeezyFormat(url: URL, finished: @escaping (URL) -> Void) {
        let asset = AVAsset(url: url)
        let compatiblePresets = AVAssetExportSession.exportPresets(compatibleWith: asset)
        
        guard
            compatiblePresets.contains(AVAssetExportPresetHighestQuality),
            let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A),
            let outputURL = self.outputURL(for: "original.m4a")
        else {
            return
        }
        
        deleteExistingOutputFile("original.m4a")
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = AVFileType.m4a
        
        exportSession.exportAsynchronously {
            switch exportSession.status {
            case .failed:
                assertionFailure("Export failed: \(exportSession.error?.localizedDescription)")
            case .cancelled:
                assertionFailure("Export canceled")
            default:
                DispatchQueue.main.async {
                    finished(outputURL)
                }
            }
        }
    }
    
    static func combineAudioFiles(audioURLs: [URL], outputURL: URL, finished: @escaping (URL) -> Void) {
        let composition = AVMutableComposition()
        let compositionAudioTrack = composition.addMutableTrack(
            withMediaType: AVMediaType.audio,
            preferredTrackID: kCMPersistentTrackID_Invalid
        )

        audioURLs.forEach {
            compositionAudioTrack?.append(url: $0)
        }

        guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A) else {
            assertionFailure("Can't create export session")
            return
        }
        
        deleteExistingOutputURL(audioURLs.first!)
        
        exportSession.outputFileType = AVFileType.m4a
        exportSession.outputURL = outputURL
        exportSession.exportAsynchronously {
            switch exportSession.status {
            case .failed:
                assertionFailure("Export failed: \(exportSession.error?.localizedDescription)")
            case .cancelled:
                assertionFailure("Export canceled")
            default:
                DispatchQueue.main.async {
                    finished(outputURL)
                }
            }
        }
    }
    
    private static func outputURL(for name: String) -> URL? {
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
    
    private static func deleteExistingOutputFile(_ name: String) {
        let fileManager = FileManager.default
        do {
            let documentDirectory = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor:nil, create:false)
            let fileURL = documentDirectory.appendingPathComponent(name)
            try fileManager.removeItem(at: fileURL)
        } catch {
            print(error)
        }
    }
    
    private static func deleteExistingOutputURL(_ url: URL) {
        let fileManager = FileManager.default
        do {
            try fileManager.removeItem(at: url)
        } catch {
            print(error)
        }
    }
}

extension AVMutableCompositionTrack {
    func append(url: URL) {
        let newAsset = AVURLAsset(url: url)
        let range = CMTimeRangeMake(start: CMTime.zero, duration: newAsset.duration)
        let end = timeRange.end
        
        if let track = newAsset.tracks(withMediaType: AVMediaType.audio).first {
            try! insertTimeRange(range, of: track, at: end)
        }
    }
}
