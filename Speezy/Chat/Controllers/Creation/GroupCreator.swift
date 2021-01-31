//
//  GroupCreator.swift
//  Speezy
//
//  Created by Matt Beaney on 28/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation
import FirebaseDatabase

class GroupCreator {
    func createChatters(
        currentChatter: Chatter,
        contacts: [Contact],
        userTokens: [UserToken],
        title: String,
        completion: @escaping (Result<Chat, Error>) -> Void
    ) {
        var chatters = contacts.map { (contact) -> Chatter in
            let userToken = userTokens.compactMap { (userToken) -> String? in
                userToken.userId == contact.userId ? userToken.token : nil
            }.first
            
            return Chatter(
                id: contact.userId,
                displayName: contact.displayName,
                profileImageUrl: contact.profilePhotoUrl,
                pushToken: userToken
            )
        }
        
        chatters.append(currentChatter)
        
        let ref = Database.database().reference()
        let groupChild = ref.child("chatters").childByAutoId()
        let group = DispatchGroup()
        
        chatters.forEach {
            group.enter()
            let chatterChild = groupChild.child($0.id)
            chatterChild.setValue($0.toDict) { (error, ref) in
                group.leave()
            }
        }
        
        group.notify(queue: DispatchQueue.global()) {
            guard let key = groupChild.key else {
                // TODO: Handle errors
                assertionFailure("Key not available")
                return
            }
            
            let newChat = Chat(
                id: key,
                chatters: chatters,
                readBy: [],
                title: title,
                lastUpdated: Date().timeIntervalSince1970,
                lastMessage: "New chat started",
                chatImageUrl: nil
            )
            
            completion(.success(newChat))
        }
    }
}
