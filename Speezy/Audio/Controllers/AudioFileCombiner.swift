//
//  VideoGenerator.swift
//  Speezy
//
//  Created by Matt Beaney on 11/07/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import Foundation
import AVKit

class AudioFileCombiner {        
    static func combineAudioFiles(audioURLs: [URL], outputURL: URL, finished: @escaping (URL) -> Void) {
        let composition = AVMutableComposition()
        let compositionAudioTrack = composition.addMutableTrack(
            withMediaType: AVMediaType.audio,
            preferredTrackID: kCMPersistentTrackID_Invalid
        )

        audioURLs.forEach {
            compositionAudioTrack?.append(url: $0)
        }

        guard
            let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A)
        else {
            assertionFailure("Can't create export session")
            return
        }
        
        FileManager.default.deleteExistingURL(audioURLs.first!)
        
        exportSession.outputFileType = AudioConstants.outputFileType
        exportSession.outputURL = outputURL
        exportSession.exportAsynchronously {
            switch exportSession.status {
            case .failed:
                assertionFailure("Export failed: \(exportSession.error)")
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
