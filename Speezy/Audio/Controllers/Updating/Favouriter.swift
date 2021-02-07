//
//  FavouriteUpdater.swift
//  Speezy
//
//  Created by Matt Beaney on 07/02/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation

class Favouriter {
    func favourite(message: Message, completion: @escaping (Result<AudioItem, Error>) -> Void) {
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
        
        let audioUpdater = AudioUpdater(kind: .favourites)
        audioUpdater.updateRecording(audioItem, completion: completion)
    }
}
