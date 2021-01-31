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
    static func downloadAudioClip(
        id: String,
        completion: @escaping (Result<AudioItem, Error>) -> Void
    ) {        
        let storage = FirebaseStorage.Storage.storage()
        let storageRef = storage.reference()
        let profileImagesRef = storageRef.child("audio_clips/\(id).m4a")
        
        let item = AudioItem(
            id: id,
            path: "\(id).m4a",
            title: "",
            date: Date(),
            tags: []
        )
        
        profileImagesRef.getMetadata { (metaData, error) in
            if
                let localLastModified = item.fileUrl.lastModified,
                let remoteLastModified = metaData?.updated,
                localLastModified > remoteLastModified,
                item.existsLocally
            {
                completion(.success(item))
            } else {
                self.downloadAudioClip(
                    ref: profileImagesRef,
                    item: item,
                    completion: completion
                )
            }
        }
    }
    
    static func downloadAudioItem(
        item: AudioItem,
        completion: @escaping (Result<AudioItem, Error>) -> Void
    ) {
        downloadAudioClip(id: item.id, completion: completion)
    }
    
    enum AudioDownloadError: Error {
        case notFound
    }
    
    private static func downloadAudioClip(
        ref: StorageReference,
        item: AudioItem,
        completion: @escaping (Result<AudioItem, Error>) -> Void
    ) {
        ref.getData(maxSize: 5 * 1024 * 1024) { data, error in
            guard let data = data else {
                completion(.failure(AudioDownloadError.notFound))
                return
            }
            
            do {
                try data.write(to: item.withStagingPath().fileUrl)
                try data.write(to: item.fileUrl)
                completion(.success(item))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    static func uploadAudioItem(
        item: AudioItem,
        completion: @escaping (StorageUploadResult) -> Void
    ) {
        guard let data = item.fileUrl.data else {
            return
        }
        
        uploadAudioClip(id: item.id, data: data, completion: completion)
    }
    
    static func uploadAudioClip(
        id: String,
        data: Data,
        completion: @escaping (StorageUploadResult) -> Void
    ) {
        // Create a root reference
        let storage = FirebaseStorage.Storage.storage()
        let storageRef = storage.reference()
        let audioClipRef = storageRef.child("audio_clips/\(id).m4a")
        
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
