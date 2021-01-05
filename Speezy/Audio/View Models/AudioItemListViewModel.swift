//
//  AudioItemListViewModel.swift
//  Speezy
//
//  Created by Matt Beaney on 05/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation

class AudioItemListViewModel {
    
    enum Change {
        case itemsLoaded
    }
    
    var didChange: ((Change) -> Void)?
    var audioItems: [AudioItem] = []
    
    private(set) var audioAttachmentManager = AudioAttachmentManager()
    
    var shouldShowEmptyView: Bool {
        audioItems.isEmpty
    }
    
    func loadItems() {
        audioItems = AudioStorage.fetchItems()
        didChange?(.itemsLoaded)
    }
    
    func reloadItem(_ item: AudioItem) {
        if audioItems.contains(item) {
            audioItems = audioItems.replacing(item)
        } else {
            audioItems.append(item)
        }
        
        audioAttachmentManager.resetCache()
        
        didChange?(.itemsLoaded)
    }
    
    func deleteItem(_ item: AudioItem) {
        audioAttachmentManager.storeAttachment(
            nil,
            forItem: item
        )
        
        FileManager.default.deleteExistingURL(
            item.withStagingPath().url
        )
        FileManager.default.deleteExistingURL(item.url)
        AudioStorage.deleteItem(item)
        audioItems = audioItems.removing(item)
        didChange?(.itemsLoaded)
    }
}

extension AudioItemListViewModel {
    var numberOfItems: Int {
        audioItems.count
    }
    
    func item(at indexPath: IndexPath) -> AudioItem {
        audioItems[indexPath.row]
    }
}

extension AudioItemListViewModel {
    var newItem: AudioItem {
        let id = UUID().uuidString
        return AudioItem(
            id: id,
            path: "\(id).\(AudioConstants.fileExtension)",
            title: "",
            date: Date(),
            tags: []
        )
    }
}
