//
//  AudioSavingManager.swift
//  Speezy
//
//  Created by Matt Beaney on 14/11/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import Foundation

class RecordingSaver {
    func discard(item: AudioItem, completion: @escaping () -> Void
    ) {
        FileManager.default.deleteExistingURL(item.withStagingPath().fileUrl)
        FileManager.default.copy(original: item.withoutStagingPath().fileUrl, to: item.withStagingPath().fileUrl)
        completion()
    }
}

// MARK: Saving
extension RecordingSaver {
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
        AudioUpdater(kind: .recordings).updateRecording(item) { (result) in
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
        guard let data = item.fileUrl.data else {
            return
        }
        
        CloudAudioManager.uploadAudioClip(
            id: item.id,
            data: data
        ) { (result) in
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
extension RecordingSaver {
    func deleteItem(
        _ item: AudioItem,
        completion: @escaping (StorageDeleteResult) -> Void
    ) {
        LocalAudioManager.deleteAudioFiles(item: item)
        CloudAudioManager.deleteAudioClip(at: "audio_clips/\(item.id).m4a") { (result) in
            switch result {
            case .success:
                AudioUpdater(kind: .recordings).removeRecording(item) { (result) in
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
