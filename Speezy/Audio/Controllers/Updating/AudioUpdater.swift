//
//  DatabaseAudioController.swift
//  Speezy
//
//  Created by Matt Beaney on 17/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation
import FirebaseAuth
import FirebaseDatabase

class AudioUpdater {
    enum Kind: String {
        case recordings
        case favourites
    }
    
    let kind: Kind
    
    init(kind: Kind) {
        self.kind = kind
    }
    
    func recordingPath(userId: String, itemId: String) -> String {
        "users/\(userId)/\(kind.rawValue)/\(itemId)"
    }
    
    func updateRecording(
        _ item: AudioItem,
        completion: @escaping (Result<AudioItem, Error>) -> Void
    ) {
        guard
            let userId = Auth.auth().currentUser?.uid,
            let itemUrl = item.remoteUrl
        else {
            return
        }
        
        let ref = Database.database().reference()
        var audioItemDict: [String: Any] = [
            "id": item.id,
            "duration": item.calculatedDuration,
            "title": item.title,
            "url": itemUrl.absoluteString,
            "last_updated": item.lastUpdated.timeIntervalSince1970,
            "last_updated_sort": -item.lastUpdated.timeIntervalSince1970
        ]
        
        if let attachmentUrl = item.attachmentUrl {
            audioItemDict["attachment_url"] = attachmentUrl.absoluteString
        }
        
        audioItemDict = updatedRecordingWithNewOccurrences(
            item: item,
            audioItemDict: audioItemDict
        )
        
        let clipChild = ref.child(
            recordingPath(userId: userId, itemId: item.id)
        )
        
        clipChild.setValue(audioItemDict) { (error, newRef) in
            completion(.success(item))
        }
    }
    
    func updatedRecordingWithNewOccurrences(item: AudioItem, audioItemDict: [String: Any]) -> [String: Any] {
        var audioItemDict = audioItemDict
        guard !item.attachedMessageIds.isEmpty else {
            return audioItemDict
        }
        
        let occurrencesString = item.attachedMessageIds.joined(separator: ",")
        audioItemDict["occurrences"] = occurrencesString
        return audioItemDict
    }
    
    func removeRecording(
        withId id: String,
        completion: ((DatabaseDeleteResult) -> Void)? = nil
    ) {
        guard
            let userId = Auth.auth().currentUser?.uid
        else {
            return
        }
        
        let ref = Database.database().reference()
        let clipChild = ref.child(
            recordingPath(userId: userId, itemId: id)
        )

        clipChild.removeValue { (error, newRef) in
            if let error = error {
                completion?(.failure(error))
            } else {
                completion?(.success)
            }
        }
    }
}
