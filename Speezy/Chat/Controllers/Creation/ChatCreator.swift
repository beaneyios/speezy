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
    func newChatId() -> String? {
        let ref = Database.database().reference()
        return ref.child("chatters").childByAutoId().key
    }
    
    func createChat(
        chatId: String,
        title: String,
        attachmentUrl: URL?,
        currentChatter: Chatter,
        contacts: [Contact],
        completion: @escaping (Result<Chat, Error>) -> Void
    ) {
        let userIds = contacts.map { $0.userId }
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
        title: String,
        currentChatter: Chatter,
        contacts: [Contact],
        attachmentUrl: URL?,
        completion: @escaping (Result<Chat, Error>) -> Void
    ) {
        var updatePaths: [AnyHashable: Any] = [:]
        let ref = Database.database().reference()
        let groupChild = ref.child("chatters/\(chatId)")
        
        let chatters = contacts.map { contact -> Chatter in
            let userToken = tokens.compactMap { (userToken) -> String? in
                userToken.userId == contact.userId ? userToken.token : nil
            }.first
            
            let chatter = Chatter(
                id: contact.userId,
                displayName: contact.displayName,
                profileImageUrl: contact.profilePhotoUrl,
                pushToken: userToken
            )
        
            return chatter
        }
        
        let readByCurrent = ReadBy(id: currentChatter.id, time: Date().timeIntervalSince1970)
                
        let newChat = Chat(
            id: chatId,
            chatters: chatters,
            readBy: [readByCurrent],
            title: title,
            lastUpdated: Date().timeIntervalSince1970,
            lastMessage: "New chat started",
            chatImageUrl: attachmentUrl
        )
        
        chatters.forEach { chatter in
            updatePaths["chatters/\(chatId)/\(chatter.id)"] = chatter.toDict
            updatePaths["users/\(chatter.id)/chats/\(chatId)"] = true
        }
        
        updatePaths["chatters/\(chatId)/\(currentChatter.id)"] = currentChatter.toDict
        updatePaths["users/\(currentChatter.id)/chats/\(chatId)"] = true
        updatePaths["chats/\(chatId)"] = newChat.toDict
        
        ref.updateChildValues(updatePaths) { (error, newRef) in
            completion(.success(newChat))
        }
    }
}
