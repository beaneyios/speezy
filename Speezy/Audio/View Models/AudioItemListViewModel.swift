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
import FirebaseDatabase

class AudioItemListViewModel: NewItemGenerating {
    
    enum Change {
        case itemsLoaded
    }
    
    enum Tab: Int {
        case myRecordings
        case favourites
    }
    
    private var moreItems: [Tab: Bool] = [
        Tab.myRecordings: true,
        Tab.favourites: true
    ]
    
    private var isLoading: [Tab: Bool] = [
        Tab.myRecordings: false,
        Tab.favourites: false
    ]
        
    private let store: Store
    private(set) var audioAttachmentManager = AudioAttachmentManager()
    private(set) var currentTab = Tab.myRecordings
    
    var didChange: ((Change) -> Void)?
    var audioItems: [AudioItem] = []
    
    private var myRecordings = [AudioItem]()
    private var favourites = [AudioItem]()
    
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
        
        store.favouritesStore.listenForRecordingItems(userId: userId)
        store.favouritesStore.addFavouriteRecordingListObserver(self)
        store.favouritesStore.fetchNextPage(userId: userId)
        
        store.myRecordingsStore.listenForRecordingItems(userId: userId)
        store.myRecordingsStore.addRecordingItemListObserver(self)
        store.myRecordingsStore.fetchNextPage(userId: userId)
    }
    
    func switchTabs(toIndex index: Int) {
        guard let tab = Tab(rawValue: index) else {
            return
        }
        
        switch tab {
        case .favourites:
            audioItems = favourites
        case .myRecordings:
            audioItems = myRecordings
        }
        
        currentTab = tab
        didChange?(.itemsLoaded)
    }
    
    func loadMoreItems() {
        guard
            let hasMoreItems = moreItems[self.currentTab], hasMoreItems,
            let isLoading = isLoading[currentTab], isLoading == false,
            let userId = Auth.auth().currentUser?.uid
        else {
            return
        }
                
        self.isLoading[currentTab] = true
        
        switch currentTab {
        case .favourites:
            store.favouritesStore.fetchNextPage(userId: userId)
        case .myRecordings:
            store.myRecordingsStore.fetchNextPage(userId: userId)
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
    
    func discardItem(_ item: AudioItem) {
        let audioManager = AudioManager(item: item)
        audioManager.discard {
            // no op
        }
    }
    
    func deleteItem(_ item: AudioItem) {
        switch currentTab {
        case .favourites:
            Favouriter().unfavourite(item)
        case .myRecordings:
            self.deleteRecording(item)
        }
    }
    
    private func deleteRecording(_ item: AudioItem) {
        audioAttachmentManager.removeAttachment(forItem: item)

        RecordingSaver().deleteItem(item) { (result) in
            switch result {
            case .success:
                // Do nothing here, it needs to be handled by the listening delegates below.
                break
            case let .failure(error):
                // TODO: Handle error
                assertionFailure("Deletion failed with error \(error.localizedDescription)")
                break
            }
        }
    }
    
    private func updateCellModels(items: [AudioItem], tab: Tab) {
        switch tab {
        case .favourites:
            self.favourites = items
        case .myRecordings:
            self.myRecordings = items
        }

        if tab == currentTab {
            audioItems = items
        }
        
        isLoading[tab] = false
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
        updateCellModels(items: recordings, tab: .myRecordings)
    }
    
    func recordingUpdated(recording: AudioItem, recordings: [AudioItem]) {
        updateCellModels(items: recordings, tab: .myRecordings)
    }
    
    func pagedRecordingsReceived(newRecordings: [AudioItem], recordings: [AudioItem]) {
        if newRecordings.count < AudioItemsFetcher.pageSize {
            moreItems[Tab.myRecordings] = false
        }
        
        if newRecordings.isEmpty {
            return
        }

        updateCellModels(items: recordings, tab: .myRecordings)
    }
    
    func recordingRemoved(recording: AudioItem, recordings: [AudioItem]) {
        updateCellModels(items: recordings, tab: .myRecordings)
    }
}

extension AudioItemListViewModel: FavouriteRecordingsListObserver {
    func favouriteAdded(favourite: AudioItem, favourites: [AudioItem]) {
        updateCellModels(items: favourites, tab: .favourites)
    }
    
    func favouriteUpdated(favourite: AudioItem, favourites: [AudioItem]) {
        updateCellModels(items: favourites, tab: .favourites)
    }
    
    func pagedFavouritesReceived(newFavourites: [AudioItem], favourites: [AudioItem]) {
        if newFavourites.count < AudioItemsFetcher.pageSize {
            moreItems[Tab.favourites] = false
        }
        
        if newFavourites.isEmpty {
            return
        }
        
        updateCellModels(items: favourites, tab: .favourites)
    }
    
    func favouriteRemoved(favourite: AudioItem, favourites: [AudioItem]) {
        updateCellModels(items: favourites, tab: .favourites)
    }
}
