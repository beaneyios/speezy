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
    func createChat(
        title: String,
        currentChatter: Chatter,
        contacts: [Contact],
        completion: @escaping (Result<Chat, Error>) -> Void
    ) {
        let userIds = contacts.map { $0.userId }
        DatabasePushTokenManager().fetchTokens(for: userIds) { (result) in
            switch result {
            case let .success(userTokens):
                self.createChat(
                    tokens: userTokens,
                    title: title,
                    currentChatter: currentChatter,
                    contacts: contacts,
                    completion: completion
                )
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
    
    private func createChat(
        tokens: [UserToken],
        title: String,
        currentChatter: Chatter,
        contacts: [Contact],
        completion: @escaping (Result<Chat, Error>) -> Void
    ) {
        var updatePaths: [AnyHashable: Any] = [:]
        let ref = Database.database().reference()
        let groupChild = ref.child("chatters").childByAutoId()
        
        guard let key = groupChild.key else {
            // TODO: Handle errors
            assertionFailure("Key not available")
            return
        }
        
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
                
        let newChat = Chat(
            id: key,
            chatters: chatters,
            readBy: [currentChatter.id],
            title: title,
            lastUpdated: Date().timeIntervalSince1970,
            lastMessage: "New chat started",
            chatImageUrl: nil
        )
        
        chatters.forEach { chatter in
            updatePaths["chatters/\(key)/\(chatter.id)"] = chatter.toDict
            updatePaths["users/\(chatter.id)/chats/\(key)"] = true
        }
        
        updatePaths["chatters/\(key)/\(currentChatter.id)"] = currentChatter.toDict
        updatePaths["users/\(currentChatter.id)/chats/\(key)"] = true
        updatePaths["chats/\(key)"] = newChat.toDict
        
        ref.updateChildValues(updatePaths) { (error, newRef) in
            completion(.success(newChat))
        }
    }
}
