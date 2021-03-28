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
        
        if let profileImages = chat.profileImages {
            let oppositeProfileId: String? = profileImages.keys.first {
                $0 != self.currentUserId
            }
            
            if let profileId = oppositeProfileId {
                downloadTask?.cancel()
                downloadTask = ProfileImageFetcher().fetchImage(id: profileId, completion: completion)
                return
            }
        }
        
        if let displayNames = chat.displayNames {
            let oppositeProfileDisplayName: [String] = displayNames.compactMap { (keyValuePair) -> String? in
                if keyValuePair.key != self.currentUserId {
                    return keyValuePair.value
                } else {
                    return nil
                }
            }
            
            if let firstName = oppositeProfileDisplayName.first, let character = firstName.first {
                completion(
                    .success(
                        SpeezyProfileViewGenerator.generateProfileImage(
                            character: String(character), color: nil
                        )
                    )
                )
                return
            }
        }
        
        // TODO: Handle image error better here.
        let error = NSError(domain: "", code: 404, userInfo: nil)
        completion(.failure(error))
    }
}
