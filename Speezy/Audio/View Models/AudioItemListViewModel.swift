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
    
    
    private let store: Store
    private(set) var audioAttachmentManager = AudioAttachmentManager()
    
    var didChange: ((Change) -> Void)?
    var audioItems: [AudioItem] = []
    
    var shouldShowEmptyView: Bool {
        audioItems.isEmpty
    }
    
    init(store: Store) {
        self.store = store
    }
    
    func loadItems() {
        guard let userId = Auth.auth().currentUser?.uid else {
            return
        }
        
        store.myRecordingsStore.addRecordingItemListObserver(self)
        store.myRecordingsStore.fetchNextPage(userId: userId)
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
    
    func discardItem(_ item: AudioItem) {
        let audioManager = AudioManager(item: item)
        audioManager.discard {
            // no op
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
    
    private func updateCellModels(recordings: [AudioItem]) {
        audioItems = recordings
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

extension AudioItemListViewModel: MyRecordingsListObserver {
    func recordingAdded(recording: AudioItem, recordings: [AudioItem]) {
        updateCellModels(recordings: recordings)
    }
    
    func recordingUpdated(recording: AudioItem, recordings: [AudioItem]) {
        updateCellModels(recordings: recordings)
    }
    
    func pagedRecordingsReceived(recordings: [AudioItem]) {
        updateCellModels(recordings: recordings)
    }
    
    func recordingRemoved(recording: AudioItem, recordings: [AudioItem]) {
        updateCellModels(recordings: recordings)
    }
}
