//
//  AudioFileManager.swift
//  Speezy
//
//  Created by Matt Beaney on 17/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation

class LocalAudioManager {
    static func syncStageWithOriginal(item: AudioItem, originalItem: AudioItem) {
        // Remove the original item (that was downloaded from the cloud).
        FileManager.default.deleteExistingFile(
            with: originalItem.path
        )
        
        // Commit the changed item to local disk space (so we don't need to keep downloading it).
        FileManager.default.copy(
            original: item.fileUrl,
            to: originalItem.fileUrl
        )
    }
    
    static func deleteAudioFiles(item: AudioItem) {
        FileManager.default.deleteExistingURL(
            item.withStagingPath().fileUrl
        )
        FileManager.default.deleteExistingURL(item.fileUrl)
    }
}
