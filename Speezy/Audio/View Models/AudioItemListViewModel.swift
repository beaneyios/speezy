//
//  AudioItemListViewModel.swift
//  Speezy
//
//  Created by Matt Beaney on 05/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation
import FirebaseAuth
import FBSDKLoginKit

class AudioItemListViewModel: NewItemGenerating {
    
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
        DatabaseAudioManager.fetchItems { (result) in
            switch result {
            case let .success(items):
                self.audioItems = items.sorted {
                    $0.lastUpdated > $1.lastUpdated
                }
                
                self.didChange?(.itemsLoaded)
            case let .failure(error):
                // TODO: Handle error
                assertionFailure("Errored with error \(error.localizedDescription)")
            }
        }
    }
    
    func saveItem(_ item: AudioItem) {
        let audioManager = AudioManager(item: item)
        audioManager.save(saveAttachment: false) { (result) in
            switch result {
            case let .success(item):
                if self.audioItems.contains(item) {
                    self.audioItems = self.audioItems.replacing(item)
                } else {
                    self.audioItems.append(item)
                }
                
                self.audioAttachmentManager.resetCache()
                self.didChange?(.itemsLoaded)
            case let .failure(error):
                break
            }
        }
    }
    
    func deleteItem(_ item: AudioItem) {
        audioAttachmentManager.removeAttachment(forItem: item)

        AudioSavingManager().deleteItem(item) { (result) in
            switch result {
            case .success:
                self.audioItems = self.audioItems.removing(item)
                self.didChange?(.itemsLoaded)
            case let .failure(error):
                // TODO: Handle error
                assertionFailure("Deletion failed with error \(error.localizedDescription)")
                break
            }
        }
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
