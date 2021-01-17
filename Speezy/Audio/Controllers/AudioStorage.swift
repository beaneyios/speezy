//
//  AudioStorage.swift
//  Speezy
//
//  Created by Matt Beaney on 20/07/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import Foundation
import FirebaseStorage
import FirebaseDatabase
import FirebaseAuth

class AudioStorage {
    private static let audioItemsKey = "audio_items"
    
    static func saveItem(
        _ item: AudioItem,
        completion: @escaping (Result<AudioItem, Error>) -> Void
    ) {
        uploadItem(item) { (result) in
            switch result {
            case let .success(item):
                DatabaseAudioController.updateDatabaseReference(
                    item,
                    completion: completion
                )
            case .failure:
                completion(result)
            }
        }
    }
    
    private static func uploadItem(
        _ item: AudioItem,
        completion: @escaping (Result<AudioItem, Error>) -> Void
    ) {
        // Create a root reference
        let storage = FirebaseStorage.Storage.storage()
        let storageRef = storage.reference()
        let audioClipRef = storageRef.child("audio_clips/\(item.id).m4a")

        guard let data = try? Data(contentsOf: item.fileUrl) else {
            return
        }
        
        audioClipRef.putData(data, metadata: nil) { (metadata, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            audioClipRef.downloadURL { (url, error) in
                if let error = error {
                    completion(.failure(error))
                } else if let url = url {
                    let audioItemWithUpdatedUrl = item.withRemoteUrl(url)
                    completion(.success(audioItemWithUpdatedUrl))
                } else {
                    // TODO: Handle nil error
                }
            }
        }
    }
    
    static func deleteItem(_ item: AudioItem) {
        var itemList = Storage.retrieve(
            audioItemsKey,
            from: .documents,
            as: [AudioItem].self
            ) ?? []
        
        itemList = itemList.removing(item)
        Storage.store(itemList, to: .documents, as: audioItemsKey)
    }
    
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
            
            self.handleSuccess(result: result, completion: completion)
        } withCancel: { (error) in
            completion(.failure(error))
        }
    }
    
    private static func handleSuccess(
        result: NSDictionary,
        completion: @escaping (Result<[AudioItem], Error>) -> Void
    ) {
        let audioItems: [AudioItem] = result.allKeys.compactMap {
            guard
                let key = $0 as? String,
                let dict = result[key] as? NSDictionary,
                let duration = dict["duration"] as? TimeInterval,
                let title = dict["title"] as? String,
                let urlString = dict["url"] as? String,
                let url = URL(string: urlString),
                let timestamp = dict["date"] as? TimeInterval
            else {
                return nil
            }
            
            return AudioItem(
                id: key,
                path: "\(key).m4a",
                title: title,
                date: Date(timeIntervalSince1970: timestamp),
                tags: [],
                remoteUrl: url
            )
        }
        
        completion(.success(audioItems))
    }
    
    static func url(for id: String) -> URL {
        FileManager.default.documentsURL(with: id)!
    }
}
