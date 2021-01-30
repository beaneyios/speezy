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
    
    private var downloadTask: StorageDownloadTask?
    
    init(chat: Chat) {
        self.chat = chat
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
    
    func loadImage(completion: @escaping (StorageFetchResult<UIImage>) -> Void) {
        if chat.chatImageUrl == nil {
            // TODO: Handle image error better here.
            let error = NSError(domain: "", code: 404, userInfo: nil)
            completion(.failure(error))
            return
        }
        
        downloadTask?.cancel()
        downloadTask = CloudImageManager.fetchImage(
            at: "chats/\(chat.id).jpg",
            completion: completion
        )
    }
}
