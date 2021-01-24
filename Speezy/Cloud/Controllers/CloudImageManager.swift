//
//  ImageUploader.swift
//  Speezy
//
//  Created by Matt Beaney on 17/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import UIKit
import FirebaseStorage

class CloudImageManager {
    static func fetchImage(
        at path: String,
        completion: @escaping (StorageFetchResult<UIImage>) -> Void
    ) {
        let storage = FirebaseStorage.Storage.storage()
        let storageRef = storage.reference()
        let profileImagesRef = storageRef.child(path)
        
        profileImagesRef.getData(maxSize: 5 * 1024 * 1024) { data, error in
            guard let data = data, let image = UIImage(data: data) else {
                // TODO: Handle error.
                completion(.failure(error))
                return
            }
            
            completion(.success(image))
        }
    }
    
    static func uploadImage(
        _ image: UIImage,
        path: String,
        completion: @escaping (StorageUploadResult) -> Void
    ) {
        let storage = FirebaseStorage.Storage.storage()
        let storageRef = storage.reference()
        let imageRef = storageRef.child(path)

        guard let data = image.compress(to: 0.5) else {
            assertionFailure("Could not compress")
            return
        }
        
        imageRef.putData(data, metadata: nil) { (metadata, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            imageRef.downloadURL { (url, error) in
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
    
    static func deleteImage(
        at path: String,
        completion: @escaping (StorageDeleteResult) -> Void
    ) {
        // Create a root reference
        let storage = FirebaseStorage.Storage.storage()
        let storageRef = storage.reference()
        
        // Create a reference to "mountains.jpg"
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
