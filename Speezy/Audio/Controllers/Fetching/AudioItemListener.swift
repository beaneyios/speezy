//
//  AudioItemListener.swift
//  Speezy
//
//  Created by Matt Beaney on 07/02/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation
import FirebaseDatabase

class AudioItemListener {
    private var currentQuery: DatabaseQuery?
    
    enum Kind: String {
        case recordings
        case favourites
    }
    
    enum Change {
        case recordingAdded(AudioItem)
        case recordingUpdated(RecordingValueChange)
        case recordingRemoved(String)
    }
    
    var didChange: ((Change) -> Void)?
    let kind: Kind
    
    init(kind: Kind) {
        self.kind = kind
    }
    
    func itemsPath(userId: String) -> String {
        "users/\(userId)/\(kind.rawValue)"
    }
    
    func itemPath(userId: String, itemId: String) -> String {
        "users/\(userId)/\(kind.rawValue)/\(itemId)"
    }
    
    func listenForAdditions(
        userId: String,
        mostRecentRecording: AudioItem?
    ) {
        currentQuery?.removeAllObservers()
        
        let ref = Database.database().reference()
        let messagesChild: DatabaseReference = ref.child(itemsPath(userId: userId))
        currentQuery = messagesChild
            .queryOrdered(byChild: "last_updated_sort")
            .queryLimited(toFirst: 1)

        currentQuery?.observe(.childAdded) { (snapshot) in
            guard let result = snapshot.value as? NSDictionary else {
                // TODO: handle error
                assertionFailure("Snapshot not dictionary")
                return
            }
            
            let key = snapshot.key
            
            guard let recording = DatabaseAudioItemParser.parseItem(key: key, dict: result) else {
                return
            }
            
            if recording != mostRecentRecording {
                self.didChange?(.recordingAdded(recording))
            } else {
                // Do nothing, we don't want to have duplicated messages.
            }
        }
    }
    
    func listenForChanges(userId: String, recordingId: String) {
        let ref = Database.database().reference()
        let chatsChild: DatabaseReference = ref.child(itemPath(userId: userId, itemId: recordingId))
        let query = chatsChild.queryOrderedByKey()
        query.observe(.childChanged) { (snapshot) in
            guard
                let value = snapshot.value,
                let recordingValue = RecordingValue(key: snapshot.key, value: value)
            else {
                return
            }
            
            
            let change = RecordingValueChange(recordingId: recordingId, recordingValue: recordingValue)
            self.didChange?(.recordingUpdated(change))
        }
    }
    
    func listenForDeletions(userId: String) {
        let ref = Database.database().reference()
        let chatsChild = ref.child(itemsPath(userId: userId))
        let query = chatsChild.queryOrderedByKey()
        query.observe(.childRemoved) { (snapshot) in
            self.didChange?(.recordingRemoved(snapshot.key))
        }
    }
}
