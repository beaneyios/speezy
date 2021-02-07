//
//  FavouritesFetcher.swift
//  Speezy
//
//  Created by Matt Beaney on 07/02/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation
import FirebaseDatabase

class FavouriteRecordingsFetcher {
    static let pageSize = 10
    
    func fetchFavouriteRecordings(
        userId: String,
        mostRecentRecording: AudioItem?,
        completion: @escaping (Result<[AudioItem], Error>) -> Void
    ) {
        let ref = Database.database().reference()
        let recordingsChild: DatabaseReference = ref.child("users/\(userId)/favourites")
        
        let query: DatabaseQuery = {
            if let mostRecentRecording = mostRecentRecording {
                return recordingsChild
                    .queryOrdered(byChild: "last_updated_sort")
                    .queryStarting(atValue: -mostRecentRecording.lastUpdated.timeIntervalSince1970)
                    .queryLimited(toFirst: UInt(Self.pageSize))
            } else {
                return recordingsChild
                    .queryOrdered(byChild: "last_updated_sort")
                    .queryLimited(toFirst: UInt(Self.pageSize))
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
