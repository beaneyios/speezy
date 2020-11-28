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
        originalItem: AudioItem
    ) -> AudioItem {
        FileManager.default.deleteExistingFile(with: originalItem.path)
        FileManager.default.copy(original: item.url, to: originalItem.url)
        
        let newItem = AudioItem(
            id: item.id,
            path: "\(item.id).wav",
            title: item.title,
            date: item.date,
            tags: item.tags
        )
        
        AudioStorage.saveItem(newItem)
        return newItem
    }
    
    func discard(
        item: AudioItem,
        originalItem: AudioItem,
        completion: @escaping () -> Void
    ) {
        FileManager.default.deleteExistingURL(item.url)
        FileManager.default.copy(original: originalItem.url, to: item.url)
        completion()
    }
}
