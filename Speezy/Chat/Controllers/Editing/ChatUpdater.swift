//
//  DatabaseChatUpdater.swift
//  Speezy
//
//  Created by Matt Beaney on 28/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation
import FirebaseDatabase

class ChatUpdater {    
    func updateReadBy(
        chatId: String,
        userId: String,
        time: TimeInterval
    ) {
        let ref = Database.database().reference()
        let groupChild = ref.child("chats/\(chatId)/read_by/\(userId)")
        groupChild.setValue(time)
    }
    
    func addUserToChat(
        chat: Chat,
        contact: Contact,
        completion: @escaping (Result<[Chatter], Error>) -> Void
    ) {
        let userIds = [contact.id]
        DatabasePushTokenManager().fetchTokens(for: userIds) { (result) in
            switch result {
            case let .success(userTokens):
                self.addUserToChat(
                    chat: chat,
                    contact: contact,
                    tokens: userTokens,
                    completion: completion
                )
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
    
    private func addUserToChat(
        chat: Chat,
        contact: Contact,
        tokens: [UserToken],
        completion: @escaping (Result<[Chatter], Error>) -> Void
    ) {
        let userToken = tokens.compactMap { (userToken) -> String? in
            userToken.userId == contact.userId ? userToken.token : nil
        }.first
        
        let chatter = Chatter(
            id: contact.userId,
            displayName: contact.displayName,
            profileImageUrl: contact.profilePhotoUrl,
            pushToken: userToken
        )
        
        var updatePaths: [AnyHashable: Any] = [:]
        let ref = Database.database().reference()
        updatePaths["chatters/\(chat.id)/\(chatter.id)"] = chatter.toDict
        updatePaths["users/\(chatter.id)/chats/\(chat.id)"] = true
        
        ref.updateChildValues(updatePaths) { (error, newRef) in
            completion(.success([chatter]))
        }
    }
}
