//
//  AudioStorage.swift
//  Speezy
//
//  Created by Matt Beaney on 20/07/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import Foundation

class AudioStorage {
    private static let audioItemsKey = "audio_items"
    
    static func saveItem(_ item: AudioItem) {
        var itemList = Storage.retrieve(
            audioItemsKey,
            from: .documents,
            as: [AudioItem].self
        ) ?? []
        
        if itemList.contains(item) {
            itemList = itemList.replacing(item)
        } else {
            itemList.append(item)
        }
        
        Storage.store(itemList, to: .documents, as: audioItemsKey)
    }
}
