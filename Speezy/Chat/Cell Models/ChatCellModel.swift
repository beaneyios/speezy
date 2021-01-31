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
        chat.title
    }
    
    var lastMessageText: String {
        chat.lastMessage
    }
    
    var lastUpdatedText: String {
        let date = Date(timeIntervalSince1970: chat.lastUpdated)
        return date.relativeTimeString
    }
    
    var showUnread: Bool {
        guard let currentUserId = currentUserId else {
            return false
        }
        
        return !chat.readBy.contains(currentUserId)
    }
    
    func loadImage(completion: @escaping (StorageFetchResult<UIImage>) -> Void) {
        if chat.chatImageUrl == nil {
            // TODO: Handle image error better here.
            let error = NSError(domain: "", code: 404, userInfo: nil)
            completion(.failure(error))
            return
        }
        
        downloadTask?.cancel()
        downloadTask = ChatImageFetcher().fetchImage(id: chat.id, completion: completion)
    }
}
