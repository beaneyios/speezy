//
//  AudioItemListener.swift
//  Speezy
//
//  Created by Matt Beaney on 06/02/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation
import FirebaseDatabase

class MyRecordingsListener {
    private var currentQuery: DatabaseQuery?
    
    enum Change {
        case recordingAdded(AudioItem)
        case recordingUpdated(RecordingValueChange)
        case recordingRemoved(String)
    }
    
    var didChange: ((Change) -> Void)?
    
    func listenForRecordingAdditions(
        userId: String,
        mostRecentRecording: AudioItem?
    ) {
        currentQuery?.removeAllObservers()
        
        let ref = Database.database().reference()
        let messagesChild: DatabaseReference = ref.child("users/\(userId)/recordings")
        currentQuery = messagesChild.queryOrderedByKey().queryLimited(toLast: 1)

        currentQuery?.observe(.childAdded) { (snapshot) in
            guard let result = snapshot.value as? NSDictionary else {
                // TODO: handle error
                assertionFailure("Snapshot not dictionary")
                return
            }
            
            let key = snapshot.key
            
            guard
                let dict = result[key] as? NSDictionary
            else {
                return
            }
            
            guard let recording = DatabaseAudioItemParser.parseItem(key: key, dict: dict) else {
                return
            }
            
            if recording != mostRecentRecording {
                self.didChange?(.recordingAdded(recording))
            } else {
                // Do nothing, we don't want to have duplicated messages.
            }
        }
    }
}
