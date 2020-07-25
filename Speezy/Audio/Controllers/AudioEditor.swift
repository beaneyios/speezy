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
            compatiblePresets.contains(AVAssetExportPresetAppleM4A),
            let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A),
            let outputURL = FileManager.default.documentsURL(with: "original.m4a")
        else {
            return
        }
        
        FileManager.default.deleteExistingFile(with: "original.m4a")
        
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
        
        FileManager.default.deleteExistingURL(audioURLs.first!)
        
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
