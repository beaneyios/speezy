//
//  CloudAudioManager.swift
//  Speezy
//
//  Created by Matt Beaney on 17/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation
import FirebaseStorage

class CloudAudioManager {
    static func fetchAudioClip(
        at path: String,
        completion: @escaping (Result<Data, Error>) -> Void
    ) {
        let storage = FirebaseStorage.Storage.storage()
        let storageRef = storage.reference()
        let profileImagesRef = storageRef.child(path)
        
        profileImagesRef.getData(maxSize: 5 * 1024 * 1024) { data, error in
            guard let data = data else {
                // TODO: Handle error.
                assertionFailure("Errored with error \(error?.localizedDescription)")
                return
            }
            
            completion(.success(data))
        }
    }
    
    static func uploadAudioClip(
        _ data: Data,
        path: String,
        completion: @escaping (StorageUploadResult) -> Void
    ) {
        // Create a root reference
        let storage = FirebaseStorage.Storage.storage()
        let storageRef = storage.reference()
        let audioClipRef = storageRef.child(path)
        
        audioClipRef.putData(data, metadata: nil) { (metadata, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            audioClipRef.downloadURL { (url, error) in
                if let error = error {
                    completion(.failure(error))
                } else if let url = url {
                    completion(.success(url))
                } else {
                    // TODO: Handle nil error
                }
            }
        }
    }
    
    static func deleteAudioClip(
        at path: String,
        completion: @escaping (StorageDeleteResult) -> Void
    ) {
        let storage = FirebaseStorage.Storage.storage()
        let storageRef = storage.reference()
        let audioClipRef = storageRef.child(path)

        audioClipRef.delete { (error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            completion(.success)
        }
    }
}
