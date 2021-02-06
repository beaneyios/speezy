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

class DatabaseAudioManager {
    static func fetchItems(completion: @escaping (Result<[AudioItem], Error>) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            return
        }
        
        let ref = Database.database().reference()
        let clipsChild: DatabaseReference = ref.child("users/\(userId)/audio_clips")
        
        clipsChild.observeSingleEvent(of: .value) { (snapshot) in
            guard let result = snapshot.value as? NSDictionary else {
                completion(.success([]))
                return
            }
            
            let audioItems: [AudioItem] = result.allKeys.compactMap {
                guard
                    let key = $0 as? String,
                    let dict = result[key] as? NSDictionary
                else {
                    return nil
                }
                
                return DatabaseAudioItemParser.parseItem(key: key, dict: dict)
            }
            
            completion(.success(audioItems))
        } withCancel: { (error) in
            completion(.failure(error))
        }
    }
    
    static func updateDatabaseReference(
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
            "last_updated": item.lastUpdated.timeIntervalSince1970
        ]
        
        if let attachmentUrl = item.attachmentUrl {
            audioItemDict["attachment_url"] = attachmentUrl.absoluteString
        }
        
        audioItemDict = updatedAudioFileWithNewOccurrences(
            item: item,
            audioItemDict: audioItemDict
        )
        
        let clipChild = ref.child("users/\(userId)/recordings/\(item.id)")
        clipChild.setValue(audioItemDict) { (error, newRef) in
            completion(.success(item))
        }
    }
    
    static func updatedAudioFileWithNewOccurrences(item: AudioItem, audioItemDict: [String: Any]) -> [String: Any] {
        var audioItemDict = audioItemDict
        guard !item.attachedMessageIds.isEmpty else {
            return audioItemDict
        }
        
        let occurrencesDict = item.attachedMessageIds.enumerated().reduce([Int: String]()) { (dict, messageId) -> [Int: String] in
            var dict = dict
            dict[messageId.offset] = messageId.element
            return dict
        }

        audioItemDict["occurrences"] = occurrencesDict
        return audioItemDict
    }
  
    // TODO: Finish association
//    static func updateOccurrencesWithNewAudioFile(messageIds: [String], item: AudioItem) {
//        var updateDict: [String: [String]]
//        let keyValuePairs: [(String, String)] = messageIds.compactMap {
//            let substrings = $0.components(separatedBy: "_")
//            if substrings.count == 2 {
//                return (substrings[0], substrings[1])
//            }
//        }
//    }
    
    static func removeDatabaseReference(
        _ item: AudioItem,
        completion: @escaping (DatabaseDeleteResult) -> Void
    ) {
        guard
            let userId = Auth.auth().currentUser?.uid
        else {
            return
        }
        
        let ref = Database.database().reference()
        let clipChild = ref.child("users/\(userId)/audio_clips/\(item.id)")
        clipChild.removeValue { (error, newRef) in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success)
            }
        }
    }
}
