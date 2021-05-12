//
//  ChatCreator.swift
//  Speezy
//
//  Created by Matt Beaney on 28/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation
import FirebaseDatabase

class ChatCreator {
    static let dynamicTitleKey = "%DISPLAY_NAME%"
    
    func newChatId() -> String? {
        let ref = Database.database().reference()
        return ref.child("chats").childByAutoId().key
    }
    
    func createChat(
        chatId: String,
        title: String?,
        attachmentUrl: URL?,
        currentChatter: Chatter,
        contacts: [Contact],
        completion: @escaping (Result<Chat, Error>) -> Void
    ) {
        let userIds = contacts.map { $0.userId } + [currentChatter.id]
        DatabasePushTokenManager().fetchTokens(for: userIds) { (result) in
            switch result {
            case let .success(userTokens):
                self.createChat(
                    chatId: chatId,
                    tokens: userTokens,
                    title: title,
                    currentChatter: currentChatter,
                    contacts: contacts,
                    attachmentUrl: attachmentUrl,
                    completion: completion
                )
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
    
    private func createChat(
        chatId: String,
        tokens: [UserToken],
        title: String?,
        currentChatter: Chatter,
        contacts: [Contact],
        attachmentUrl: URL?,
        completion: @escaping (Result<Chat, Error>) -> Void
    ) {
        var updatePaths: [AnyHashable: Any] = [:]
        let ref = Database.database().reference()
        
        let chatters = contacts.map { contact -> Chatter in
            let chatter = Chatter(
                id: contact.userId,
                displayName: contact.displayName,
                profileImageUrl: contact.profilePhotoUrl,
                color: UIColor.random
            )
    
            return chatter
        }.appending(element: currentChatter)
        
        let lastUpdated = Date().timeIntervalSince1970
        var readBy = [String: TimeInterval]()
        chatters.forEach {
            readBy[$0.id] = lastUpdated
        }
                
        let newChat = Chat(
            id: chatId,
            title: title ?? Self.dynamicTitleKey,
            lastUpdated: lastUpdated,
            lastMessage: "New chat started",
            chatImageUrl: attachmentUrl,
            readBy: readBy,
            pushTokens: tokens,
            chatters: chatters,
            ownerId: currentChatter.id
        )
        
        chatters.forEach { chatter in
            updatePaths["users/\(chatter.id)/chats/\(chatId)"] = true
        }
        
        updatePaths["users/\(currentChatter.id)/chats/\(chatId)"] = true
        updatePaths["chats/\(chatId)"] = newChat.toDict
        
        ref.updateChildValues(updatePaths) { (error, newRef) in
            completion(.success(newChat))
        }
    }
}
