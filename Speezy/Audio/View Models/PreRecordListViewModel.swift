//
//  PreRecordListViewModel.swift
//  Speezy
//
//  Created by Matt Beaney on 06/06/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation
import FirebaseAuth

class PreRecordListViewModel: NewItemGenerating {
    
    enum Change {
        case itemsLoaded
        case loading(Bool)
    }
    
    enum Tab: Int {
        case myRecordings
    }
    
    private var moreItems: [Tab: Bool] = [
        Tab.myRecordings: true
    ]
    
    private var isLoading: [Tab: Bool] = [
        Tab.myRecordings: false
    ]
        
    private(set) var audioAttachmentManager = AudioAttachmentManager()
    private(set) var currentTab = Tab.myRecordings
    
    var didChange: ((Change) -> Void)?
    var audioItems: [AudioItem] = []
    
    private var myRecordings = [AudioItem]()
    
    var shouldShowEmptyView: Bool {
        audioItems.isEmpty
    }
    
    // Just to pass through to the edit view.
    let originalAudioItem: AudioItem
    
    init(originalAudioItem: AudioItem) {
        self.originalAudioItem = originalAudioItem
    }
    
    func loadItems() {
        loadItems(mostRecentItem: nil)
    }
    
    private func loadItems(mostRecentItem: AudioItem?) {
        guard let userId = Auth.auth().currentUser?.uid else {
            return
        }
        
        didChange?(.loading(true))

        PreRecordedAudioItemsFetcher().fetch(
            userId: userId,
            mostRecentRecording: nil)
        { (result) in
            switch result {
            case let .success(items):
                self.updateCellModels(items: items, tab: .myRecordings)
                self.didChange?(.itemsLoaded)
                self.didChange?(.loading(true))
            case let .failure(error):
                break
            }
        }
    }
    
    func loadMoreItems() {
        guard
            let hasMoreItems = moreItems[self.currentTab], hasMoreItems,
            let isLoading = isLoading[currentTab], isLoading == false
        else {
            return
        }
                
        self.isLoading[currentTab] = true
        
        loadItems(mostRecentItem: audioItems.last)
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
    
    private func updateCellModels(items: [AudioItem], tab: Tab) {
        switch tab {
        case .myRecordings:
            self.myRecordings = items
        }

        if tab == currentTab {
            audioItems = items
        }
        
        isLoading[tab] = false
        didChange?(.itemsLoaded)
        didChange?(.loading(false))
    }
}

extension PreRecordListViewModel {
    var numberOfItems: Int {
        audioItems.count
    }
    
    func item(at indexPath: IndexPath) -> AudioItem {
        audioItems[indexPath.row]
    }
}

//extension PreRecordListViewModel: MyRecordingsListObserver {
//    func recordingAdded(recording: AudioItem, recordings: [AudioItem]) {
//        updateCellModels(items: recordings, tab: .myRecordings)
//    }
//
//    func recordingUpdated(recording: AudioItem, recordings: [AudioItem]) {
//        updateCellModels(items: recordings, tab: .myRecordings)
//    }
//
//    func pagedRecordingsReceived(newRecordings: [AudioItem], recordings: [AudioItem]) {
//        if newRecordings.count < AudioItemsFetcher.pageSize {
//            moreItems[Tab.myRecordings] = false
//        }
//
//        if newRecordings.isEmpty {
//            didChange?(.loading(false))
//            return
//        }
//
//        updateCellModels(items: recordings, tab: .myRecordings)
//    }
//
//    func recordingRemoved(recording: AudioItem, recordings: [AudioItem]) {
//        updateCellModels(items: recordings, tab: .myRecordings)
//    }
//
//    func initialRecordingsReceived(recordings: [AudioItem]) {
//        updateCellModels(items: recordings, tab: .myRecordings)
//    }
//}
