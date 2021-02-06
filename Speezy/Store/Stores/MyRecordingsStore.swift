//
//  RecordingItemStore.swift
//  Speezy
//
//  Created by Matt Beaney on 06/02/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation

class MyRecordingsStore {
    private let myRecordingsListener = MyRecordingsListener()
    private let myRecordingsFetcher = MyRecordingsFetcher()
    
    private(set) var myRecordings = [AudioItem]()
    
    private var observations = [ObjectIdentifier : MyRecordingsListObservation]()
    private let serialQueue = DispatchQueue(label: "com.speezy.myRecordingsActions")
    
    func clear() {
        self.myRecordings = []
        self.observations = [:]
    }
    
    func fetchNextPage(userId: String) {
        myRecordingsFetcher.fetchMyRecordings(userId: userId, mostRecentRecording: myRecordings.first) { (result) in
            switch result {
            case let .success(newRecordings):
                self.myRecordings.append(contentsOf: newRecordings)
            case .failure:
                break
            }
        }
    }
    
    func listenForRecordingItems(userId: String) {
        myRecordingsListener.didChange = { change in
            // We do not want to manipulate the recordingItems available until the notifier has
            // finished notifying any newly added observers, so we need a queue.
            self.serialQueue.async {
                switch change {
                case let .recordingAdded(recording):
                    self.handleRecordingAdded(recording: recording)
                case let .recordingUpdated(change):
                    self.handleRecordingUpdated(change: change)
                case let .recordingRemoved(id):
                    self.handleRecordingRemoved(recordingId: id)
                }
            }
        }
        
        myRecordingsListener.listenForRecordingAdditions(userId: userId, mostRecentRecording: myRecordings.first)
    }
    
    private func handleRecordingAdded(recording: AudioItem) {
        if myRecordings.contains(recording) {
            return
        }
        
        myRecordings.append(recording)
        sortRecordings()
        notifyObservers(
            change: .recordingAdded(
                recording: recording,
                recordings: myRecordings
            )
        )
    }
    
    private func handleRecordingUpdated(change: RecordingValueChange) {
        // Find the recordingItem to update.
        let recordingToUpdate = myRecordings.first {
            change.recordingId == $0.id
        }
        
        // Apply the change.
        let newRecording: AudioItem? = {
            return recordingToUpdate
        }()
        
        // Replace the old recordingItem with the new one.
        if let newRecording = newRecording {
            replaceRecording(recordingItem: newRecording)
            sortRecordings()
            notifyObservers(
                change: .recordingUpdated(
                    recording: newRecording,
                    recordings: myRecordings
                )
            )
        }
    }
    
    private func handleRecordingRemoved(recordingId: String) {
        guard let recording = myRecordings.first(withId: recordingId) else {
            return
        }
        
        myRecordings = myRecordings.removing(recording)
        sortRecordings()
        notifyObservers(
            change: .recordingRemoved(
                recording: recording,
                recordings: myRecordings
            )
        )
    }
    
    private func replaceRecording(recordingItem: AudioItem) {
        myRecordings = myRecordings.replacing(recordingItem)
    }
    
    private func sortRecordings() {
        myRecordings = myRecordings.sorted(by: { (recordingItem1, recordingItem2) -> Bool in
            recordingItem1.lastUpdated > recordingItem2.lastUpdated
        })
    }
}

extension MyRecordingsStore {
    enum Change {
        case recordingAdded(recording: AudioItem, recordings: [AudioItem])
        case recordingUpdated(recording: AudioItem, recordings: [AudioItem])
        case initialRecordings(recordings: [AudioItem])
        case pagedRecordings(recordings: [AudioItem])
        case recordingRemoved(recording: AudioItem, recordings: [AudioItem])
    }
    
    func addRecordingItemListObserver(_ observer: MyRecordingsListObserver) {
        serialQueue.async {
            let id = ObjectIdentifier(observer)
            self.observations[id] = MyRecordingsListObservation(observer: observer)
            
            // We might be mid-load, let's give the new subscriber what we have so far.
            observer.initialRecordingsReceived(recordings: self.myRecordings)
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
            case let .recordingAdded(recording, myRecordings):
                observer.recordingAdded(recording: recording, recordings: myRecordings)
            case let .recordingUpdated(recording, myRecordings):
                observer.recordingUpdated(recording: recording, recordings: myRecordings)
            case let .initialRecordings(recording):
                observer.initialRecordingsReceived(recordings: myRecordings)
            case let .recordingRemoved(recording, myRecordings):
                observer.recordingRemoved(recording: recording, recordings: myRecordings)
            case let .pagedRecordings(recordings):
                observer.pagedRecordingsReceived(newRecordings: recordings)
            }
        }
    }
}
