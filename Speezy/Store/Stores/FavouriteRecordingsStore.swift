//
//  FavouriteRecordingsStore.swift
//  Speezy
//
//  Created by Matt Beaney on 07/02/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation

class FavouriteRecordingsStore {
    private let favouritesListener = AudioItemListener(kind: .favourites)
    private let favouritesFetcher = AudioItemsFetcher(kind: .favourites)
    
    private(set) var favourites = [AudioItem]()
    
    private var observations = [ObjectIdentifier : FavouriteRecordingsListObservation]()
    private let serialQueue = DispatchQueue(label: "com.speezy.favouritesActions")
    
    func clear() {
        self.favourites = []
        self.observations = [:]
    }
    
    func fetchNextPage(userId: String) {
        favouritesFetcher.fetch(
            userId: userId,
            mostRecentRecording: favourites.last
        ) { (result) in
            self.serialQueue.async {
                let oldFavourites = self.favourites
                
                switch result {
                case let .success(newRecordings):
                    self.handleNewPage(userId: userId, recordings: newRecordings)
                    self.listenForRecordingItems(userId: userId)
                case .failure:
                    break
                }
                
                if oldFavourites.isEmpty {
                    // This is the first load and we've now processed the the first page.
                    // So now we can start listening for additions, knowing that the first addition
                    // will be a duplicate, but will get processed.
                    self.favouritesListener.listenForAdditions(
                        userId: userId,
                        mostRecentRecording: self.favourites.first
                    )
                    
                    self.favouritesListener.listenForDeletions(userId: userId)
                }
            }
        }
    }
    
    func listenForRecordingItems(userId: String) {
        favouritesListener.didChange = { change in
            // We do not want to manipulate the recordingItems available until the notifier has
            // finished notifying any newly added observers, so we need a queue.
            self.serialQueue.async {
                switch change {
                case let .recordingAdded(recording):
                    self.handleRecordingAdded(recording: recording)
                    
                    self.favouritesListener.listenForChanges(
                        userId: userId,
                        recordingId: recording.id
                    )
                case let .recordingUpdated(change):
                    self.handleRecordingUpdated(change: change)
                case let .recordingRemoved(id):
                    self.handleRecordingRemoved(recordingId: id)
                }
            }
        }
    }
    
    private func handleNewPage(userId: String, recordings: [AudioItem]) {
        // Now we have a new page, we need to attach change listeners to the items.
        recordings.forEach {
            self.favouritesListener.listenForChanges(
                userId: userId,
                recordingId: $0.id
            )
        }
        
        favourites.append(contentsOf: recordings)
        sortRecordings()
        notifyObservers(
            change: .pagedRecordings(
                newRecordings: recordings,
                recordings: favourites
            )
        )
    }
    
    private func handleRecordingAdded(recording: AudioItem) {
        if favourites.contains(recording) {
            return
        }
        
        favourites.append(recording)
        sortRecordings()
        notifyObservers(
            change: .recordingAdded(
                recording: recording,
                recordings: favourites
            )
        )
    }
    
    private func handleRecordingUpdated(change: RecordingValueChange) {
        // Find the recordingItem to update.
        let recordingToUpdate = favourites.first {
            change.recordingId == $0.id
        }
        
        // Apply the change.
        let newRecording: AudioItem? = {
            switch change.recordingValue {
            case let .duration(duration):
                return recordingToUpdate?.withDuration(duration)
            case let .lastUpdated(lastUpdated):
                return recordingToUpdate?.withLastUpdated(Date(timeIntervalSince1970: lastUpdated))
            case let .title(title):
                return recordingToUpdate?.withUpdatedTitle(title)
            }
        }()
        
        // Replace the old recordingItem with the new one.
        if let newRecording = newRecording {
            replaceRecording(recordingItem: newRecording)
            sortRecordings()
            notifyObservers(
                change: .recordingUpdated(
                    recording: newRecording,
                    recordings: favourites
                )
            )
        }
    }
    
    private func handleRecordingRemoved(recordingId: String) {
        guard let recording = favourites.first(withId: recordingId) else {
            return
        }
        
        favourites = favourites.removing(recording)
        sortRecordings()
        notifyObservers(
            change: .recordingRemoved(
                recording: recording,
                recordings: favourites
            )
        )
    }
    
    private func replaceRecording(recordingItem: AudioItem) {
        favourites = favourites.replacing(recordingItem)
    }
    
    private func sortRecordings() {
        favourites = favourites.sorted(by: { (recordingItem1, recordingItem2) -> Bool in
            recordingItem1.lastUpdated > recordingItem2.lastUpdated
        })
    }
}

extension FavouriteRecordingsStore {
    enum Change {
        case recordingAdded(recording: AudioItem, recordings: [AudioItem])
        case recordingUpdated(recording: AudioItem, recordings: [AudioItem])
        case pagedRecordings(newRecordings: [AudioItem], recordings: [AudioItem])
        case recordingRemoved(recording: AudioItem, recordings: [AudioItem])
    }
    
    func addFavouriteRecordingListObserver(_ observer: FavouriteRecordingsListObserver) {
        serialQueue.async {
            let id = ObjectIdentifier(observer)
            self.observations[id] = FavouriteRecordingsListObservation(observer: observer)
        }
    }
    
    func removeRecordingItemListObserver(_ observer: MyRecordingsListObserver) {
        serialQueue.async {
            let id = ObjectIdentifier(observer)
            self.observations.removeValue(forKey: id)
        }
    }
    
    private func notifyObservers(change: Change) {
        observations.forEach {
            guard let observer = $0.value.observer else {
                observations.removeValue(forKey: $0.key)
                return
            }
            
            switch change {
            case let .recordingAdded(favourite, favourites):
                observer.favouriteAdded(favourite: favourite, favourites: favourites)
            case let .recordingUpdated(favourite, favourites):
                observer.favouriteUpdated(favourite: favourite, favourites: favourites)
            case let .recordingRemoved(favourite, favourites):
                observer.favouriteRemoved(favourite: favourite, favourites: favourites)
            case let .pagedRecordings(newFavourites, favourites):
                observer.pagedFavouritesReceived(newFavourites: newFavourites, favourites: favourites)
            }
        }
    }
}
