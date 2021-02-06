//
//  MyRecordingsFetcher.swift
//  Speezy
//
//  Created by Matt Beaney on 06/02/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation
import FirebaseDatabase

class MyRecordingsFetcher {
    func fetchMyRecordings(
        userId: String,
        mostRecentRecording: AudioItem?,
        completion: @escaping (Result<[AudioItem], Error>) -> Void
    ) {
        let ref = Database.database().reference()
        let chatChild: DatabaseReference = ref.child("user/\(userId)/recordings")
        
        let query: DatabaseQuery = {
            if let mostRecentRecording = mostRecentRecording {
                return chatChild
                    .queryOrderedByKey()
                    .queryEnding(atValue: mostRecentRecording.id)
                    .queryLimited(toLast: 10)
            } else {
                return chatChild.queryOrderedByKey().queryLimited(toLast: 10)
            }
        }()
        
        query.observeSingleEvent(of: .value) { (snapshot) in
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
            }.sorted {
                $0.lastUpdated > $1.lastUpdated
            }.filter {
                $0 != mostRecentRecording
            }
            
            completion(.success(audioItems))
        } withCancel: { (error) in
            completion(.failure(error))
        }
    }
}
