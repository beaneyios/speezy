//
//  ChatImageFetcher.swift
//  Speezy
//
//  Created by Matt Beaney on 31/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation
import FirebaseStorage

class ChatImageFetcher {
    @discardableResult
    func fetchImage(
        id: String,
        completion: @escaping (StorageFetchResult<UIImage>) -> Void
    ) -> StorageDownloadTask? {
        let storage = FirebaseStorage.Storage.storage()
        let storageRef = storage.reference()
        
        let profileImagesRef = storageRef.child("chats/\(id).jpg")
        
        guard
            let localUrl = FileManager.default.documentsURL(with: "\(id).jpg"),
            let localData = localUrl.data,
            let localImage = UIImage(data: localData),
            let localLastModified = localUrl.lastModified
        else {
            return downloadImage(
                id: id,
                ref: profileImagesRef,
                completion: completion
            )
        }
        
        // If it's only been thirty seconds, don't re-download.
        let thirtyMinutesAgo = 30.0 * 60.0
        let thirtyMinutesAgoDate = Date().addingTimeInterval(
            thirtyMinutesAgo * -1.0
        )
        
        if localLastModified > thirtyMinutesAgoDate {
            completion(.success(localImage))
            return nil
        } else {
            return downloadImage(
                id: id,
                ref: profileImagesRef,
                completion: completion
            )
        }
    }
    
    @discardableResult
    func downloadImage(
        id: String,
        ref: StorageReference,
        completion: @escaping (StorageFetchResult<UIImage>) -> Void
    ) -> StorageDownloadTask {
        ref.getData(maxSize: 5 * 1024 * 1024) { data, error in
            guard let data = data, let image = UIImage(data: data) else {
                // TODO: Handle error.
                completion(.failure(error))
                return
            }
            
            if let localUrl = FileManager.default.documentsURL(with: "\(id).jpg") {
                try? data.write(to: localUrl)
            }
            
            completion(.success(image))
        }
    }
}
