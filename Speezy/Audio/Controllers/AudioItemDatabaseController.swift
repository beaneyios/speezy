//
//  AudioItemDatabaseController.swift
//  Speezy
//
//  Created by Matt Beaney on 17/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation
import FirebaseAuth
import FirebaseDatabase

class AudioItemDatabaseController {
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
        let audioItemDict: [String: Any] = [
            "id": item.id,
            "duration": item.duration,
            "title": item.title,
            "url": itemUrl.absoluteString,
            "date": item.date.timeIntervalSince1970
        ]
        
        let clipChild = ref.child("users/\(userId)/audio_clips/\(item.id)")
        
        clipChild.setValue(audioItemDict) { (error, newRef) in
            completion(.success(item))
        }
    }
}
