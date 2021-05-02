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
        contact: Contact
    ) {
        let userIds = [contact.id]
        DatabasePushTokenManager().fetchTokens(for: userIds) { (result) in
            switch result {
            case let .success(userTokens):
                self.addUserToChat(
                    chat: chat,
                    contact: contact,
                    tokens: userTokens
                )
            case let .failure(error):
                break
            }
        }
    }
    
    private func addUserToChat(
        chat: Chat,
        contact: Contact,
        tokens: [UserToken]
    ) {
        let userToken = tokens.compactMap { (userToken) -> String? in
            userToken.userId == contact.userId ? userToken.token : nil
        }.first
        
        let chatter = Chatter(
            id: contact.userId,
            displayName: contact.displayName,
            profileImageUrl: contact.profilePhotoUrl,
            color: .random
        )
        
        var updatePaths: [AnyHashable: Any] = [:]
        let ref = Database.database().reference()
        updatePaths["chats/\(chat.id)/chatters/\(chatter.id)"] = chatter.toDict
        updatePaths["chats/\(chat.id)/push_tokens/\(contact.id)"] = userToken
        updatePaths["users/\(chatter.id)/chats/\(chat.id)"] = true
        ref.updateChildValues(updatePaths)
    }
}
