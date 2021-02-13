//
//  FavouriteUpdater.swift
//  Speezy
//
//  Created by Matt Beaney on 07/02/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation
import FirebaseDatabase

class Favouriter {
    let audioUpdater = AudioUpdater(kind: .favourites)
    
    func toggleFavourite(
        currentFavourites: [AudioItem],
        message: Message,
        completion: @escaping (Result<Bool, Error>) -> Void
    ) {
        if
            let audioId = message.audioId,
            currentFavourites.contains(elementWithId: audioId)
        {
            unfavourite(message: message, completion: completion)
        } else {
            favourite(message: message, completion: completion)
        }
    }
    
    func unfavourite(_ item: AudioItem) {
        audioUpdater.removeRecording(withId: item.id)
    }
    
    private func unfavourite(
        message: Message,
        completion: @escaping (Result<Bool, Error>) -> Void
    ) {
        guard let audioId = message.audioId else {
            return
        }
        
        audioUpdater.removeRecording(withId: audioId) { (result) in
            switch result {
            case .success:
                completion(.success(false))
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
    
    private func favourite(
        message: Message,
        completion: @escaping (Result<Bool, Error>) -> Void
    ) {
        guard
            let audioId = message.audioId,
            let audioUrl = message.audioUrl,
            let duration = message.duration
        else {
            return
        }
        
        let audioItem = AudioItem(
            id: audioId,
            path: "\(audioId).m4a",
            title: message.message ?? "Message from \(message.chatter.displayName)",
            date: Date(),
            tags: [],
            remoteUrl: audioUrl,
            attachmentUrl: message.attachmentUrl,
            duration: duration,
            attachedMessageIds: [message.id]
        )
        
        audioUpdater.updateRecording(audioItem) { (result) in
            switch result {
            case let .success(item):
                completion(.success(true))
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
}
