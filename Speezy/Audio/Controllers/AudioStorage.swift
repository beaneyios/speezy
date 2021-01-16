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
                self.createDatabaseReference(
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
        
        // Create a reference to "mountains.jpg"
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
    
    private static func createDatabaseReference(
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
            "date": item.date.toString()
        ]
        
        let clipChild: DatabaseReference = {
            let audioClipsChild = ref.child("users/\(userId)/audio_clips")
            if let existingKey = item.databaseKey {
                return audioClipsChild.child(existingKey)
            } else {
                return audioClipsChild.childByAutoId()
            }
        }()
        
        clipChild.setValue(audioItemDict) { (error, newRef) in
            guard let newKey = newRef.key else {
                assertionFailure("There was an error")
                return
            }
            
            let itemWithNewKey = item.withNewDatabaseKey(newKey)
            completion(.success(itemWithNewKey))
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
    
    static func fetchItems(completion: @escaping (Result<[RemoteAudioItem], Error>) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            return
        }
        
        let ref = Database.database().reference()
        let clipsChild: DatabaseReference = ref.child("users/\(userId)/audio_clips")
        
        
        clipsChild.observeSingleEvent(of: .value) { (snapshot) in
            guard let result = snapshot.value as? NSDictionary else {
                // TODO: Handle error here
                assertionFailure("Something went wrong with snapshot")
                return
            }
            
            let audioItems: [RemoteAudioItem] = result.allKeys.compactMap {
                guard
                    let key = $0 as? String,
                    let dict = result[key] as? NSDictionary,
                    let duration = dict["duration"] as? TimeInterval,
                    let id = dict["id"] as? String,
                    let title = dict["title"] as? String,
                    let urlString = dict["url"] as? String,
                    let url = URL(string: urlString)
                else {
                    return nil
                }
                
                return RemoteAudioItem(
                    duration: duration,
                    id: id,
                    title: title,
                    url: url,
                    databaseKey: key,
                    date: nil,
                    tags: nil
                )
            }
            
            completion(.success(audioItems))
        }
    }
    
    static func url(for id: String) -> URL {
        FileManager.default.documentsURL(with: id)!
    }
}

struct RemoteAudioItem {
    let duration: TimeInterval
    let id: String
    let title: String
    let url: URL
    let databaseKey: String
    let date: Date?
    let tags: [Tag]?
}
