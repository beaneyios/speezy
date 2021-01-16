//
//  AudioSavingManager.swift
//  Speezy
//
//  Created by Matt Beaney on 14/11/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import Foundation

class AudioSavingManager {
    @discardableResult
    func saveItem(
        item: AudioItem,
        originalItem: AudioItem,
        completion: @escaping (Result<AudioItem, Error>) -> Void
    ) {
        FileManager.default.deleteExistingFile(
            with: originalItem.path
        )
        FileManager.default.copy(
            original: item.fileUrl,
            to: originalItem.fileUrl
        )
        
        let newItem = AudioItem(
            id: item.id,
            path: "\(item.id).\(AudioConstants.fileExtension)",
            title: item.title,
            date: item.date,
            tags: item.tags
        )
        
        AudioStorage.saveItem(item, completion: completion)
    }
    
    func discard(
        item: AudioItem,
        originalItem: AudioItem,
        completion: @escaping () -> Void
    ) {
        FileManager.default.deleteExistingURL(item.fileUrl)
        FileManager.default.copy(original: originalItem.fileUrl, to: item.fileUrl)
        completion()
    }
}
