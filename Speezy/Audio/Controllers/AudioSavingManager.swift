//
//  AudioSavingManager.swift
//  Speezy
//
//  Created by Matt Beaney on 14/11/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import Foundation

class AudioSavingManager {
    func discard(
        item: AudioItem,
        originalItem: AudioItem,
        completion: @escaping () -> Void
    ) {
        FileManager.default.deleteExistingURL(item.fileUrl)
        FileManager.default.copy(original: originalItem.fileUrl, to: item.fileUrl)
        completion()
    }
}

// MARK: Saving
extension AudioSavingManager {
    func saveItem(
        item: AudioItem,
        originalItem: AudioItem,
        completion: @escaping (Result<AudioItem, Error>) -> Void
    ) {
        uploadItem(item) { (result) in
            switch result {
            case let .success(item):
                self.updateDatabaseRecordAndLocalFiles(
                    item: item,
                    originalItem: originalItem,
                    completion: completion
                )
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
    
    private func updateDatabaseRecordAndLocalFiles(
        item: AudioItem,
        originalItem: AudioItem,
        completion: @escaping (Result<AudioItem, Error>) -> Void
    ) {
        DatabaseAudioManager.updateDatabaseReference(item) { (result) in
            switch result {
            case let .success(item):
                LocalAudioManager.syncStageWithOriginal(
                    item: item,
                    originalItem: originalItem
                )
                
                completion(.success(item))
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

// MARK: Deleting
extension AudioSavingManager {
    func deleteItem(
        _ item: AudioItem,
        completion: @escaping (StorageDeleteResult) -> Void
    ) {
        LocalAudioManager.deleteAudioFiles(item: item)
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
}
