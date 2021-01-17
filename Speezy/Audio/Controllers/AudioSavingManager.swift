//
//  AudioSavingManager.swift
//  Speezy
//
//  Created by Matt Beaney on 14/11/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import Foundation

class AudioSavingManager {
    func saveItem(
        item: AudioItem,
        originalItem: AudioItem,
        completion: @escaping (Result<AudioItem, Error>) -> Void
    ) {
        // Remove the original item (that was downloaded from the cloud).
        FileManager.default.deleteExistingFile(
            with: originalItem.path
        )
        
        // Commit the changed item to local disk space (so we don't need to keep downloading it).
        FileManager.default.copy(
            original: item.fileUrl,
            to: originalItem.fileUrl
        )
        
        // Save the new clip to the cloud.
        let newItem = AudioItem(
            id: item.id,
            path: "\(item.id).\(AudioConstants.fileExtension)",
            title: item.title,
            date: Date(),
            tags: item.tags
        )
        
        uploadItem(newItem) { (result) in
            switch result {
            case let .success(item):
                DatabaseAudioManager.updateDatabaseReference(
                    item,
                    completion: completion
                )
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
    
    func discard(
        item: AudioItem,
        originalItem: AudioItem,
        completion: @escaping () -> Void
    ) {
        FileManager.default.deleteExistingURL(item.fileUrl)
        FileManager.default.copy(original: originalItem.fileUrl, to: item.fileUrl)
        completion()
    }
    
    func deleteItem(
        _ item: AudioItem,
        completion: @escaping (StorageDeleteResult) -> Void
    ) {
        FileManager.default.deleteExistingURL(
            item.withStagingPath().fileUrl
        )
        FileManager.default.deleteExistingURL(item.fileUrl)
        CloudAudioManager.deleteAudioClip(at: "audio_clips/\(item.id).m4a") { (result) in
            switch result {
            case .success:
                DatabaseAudioManager.removeDatabaseReference(item) { (result) in
                    switch result {
                    case .success:
                        completion(.success)
                    case let .failure(error):
                        completion(.failure(error))
                    }
                }
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
    
    private func uploadItem(
        _ item: AudioItem,
        completion: @escaping (Result<AudioItem, Error>) -> Void
    ) {
        guard let data = try? Data(contentsOf: item.fileUrl) else {
            return
        }
        
        CloudAudioManager.uploadAudioClip(data, path: "audio_clips/\(item.id).m4a") { (result) in
            switch result {
            case let .success(url):
                let audioItemWithUpdatedUrl = item.withRemoteUrl(url)
                completion(.success(audioItemWithUpdatedUrl))
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
}
