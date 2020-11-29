//
//  AudioItemChangeManager.swift
//  Speezy
//
//  Created by Matt Beaney on 29/11/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import Foundation

class AudioItemChangeManager {
    static let key = "audio_items_with_unsaved_changes"
    
    static func storeUnsavedChange(for item: AudioItem) {
        var itemList = Storage.retrieve(
            key,
            from: .documents,
            as: [AudioItem].self
        ) ?? []
        
        if itemList.contains(item) {
            itemList = itemList.replacing(item)
        } else {
            itemList.append(item)
        }
        
        Storage.store(itemList, to: .documents, as: key)
    }
    
    static func itemHasUnsavedChanges(_ item: AudioItem) -> Bool {
        fetchItems().contains { (changedItem) -> Bool in
            changedItem.id == item.id
        }
    }
    
    static func fetchItems() -> [AudioItem] {
        Storage.retrieve(key, from: .documents, as: [AudioItem].self) ?? []
    }
    
    static func removeUnsavedChange(for item: AudioItem) {
        var itemList = Storage.retrieve(
            key,
            from: .documents,
            as: [AudioItem].self
        ) ?? []
        
        itemList = itemList.removing(item)
        Storage.store(itemList, to: .documents, as: key)
    }
}
