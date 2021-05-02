//
//  ChatCellModel.swift
//  Speezy
//
//  Created by Matt Beaney on 23/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import UIKit
import FirebaseStorage

class ChatCellModel: Identifiable {
    var id: String {
        chat.id
    }
    
    let chat: Chat
    let currentUserId: String?
    
    private var downloadTask: StorageDownloadTask?
    
    init(chat: Chat, currentUserId: String?) {
        self.chat = chat
        self.currentUserId = currentUserId
    }
}

extension ChatCellModel {
    var titleText: String {
        chat.computedTitle(currentUserId: currentUserId)
    }
    
    var lastMessageText: String {
        chat.lastMessage
    }
    
    var lastUpdatedText: String {
        let date = Date(timeIntervalSince1970: chat.lastUpdated)
        return date.relativeTimeString
    }
    
    var showRead: Bool {
        guard
            let currentUserId = currentUserId,
            let readBy = chat.readBy[currentUserId]
        else {
            return false
        }
        
        return readBy >= chat.lastUpdated
    }
    
    func loadImage(completion: @escaping (StorageFetchResult<UIImage>) -> Void) {
        if chat.chatImageUrl != nil {
            downloadTask?.cancel()
            downloadTask = ChatImageFetcher().fetchImage(id: chat.id, completion: completion)
            return
        }
        
        let chatters = chat.chatters
        let oppositeChatter: Chatter? = chatters.first {
            $0.id != self.currentUserId
        }
        
        if let profileId = oppositeChatter?.id, oppositeChatter?.profileImageUrl != nil {
            downloadTask?.cancel()
            downloadTask = ProfileImageFetcher().fetchImage(id: profileId, completion: completion)
            return
        }
        
        if let character = oppositeChatter?.displayName.first {
            completion(
                .success(
                    SpeezyProfileViewGenerator.generateProfileImage(
                        character: String(character),
                        color: oppositeChatter?.color
                    )
                )
            )
            return
        }
    }
}
