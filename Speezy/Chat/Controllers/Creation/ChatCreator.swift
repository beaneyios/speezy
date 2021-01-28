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
                GroupCreator().createChatters(
                    currentChatter: currentChatter,
                    contacts: contacts,
                    userTokens: userTokens,
                    title: title
                ) { (result) in
                    switch result {
                    case let .success(chat):
                        self.createChat(chat: chat, completion: completion)
                    case let .failure(error):
                        completion(.failure(error))
                    }
                }
            case let .failure(error):
                break
            }
        }
    }
    
    private func createChat(
        chat: Chat,
        completion: @escaping (Result<Chat, Error>) -> Void
    ) {
        insertChatIntoDatabase(chat: chat) { (result) in
            switch result {
            case let .success(chat):
                ChatUserUpdater().updateUserChatLists(
                    with: chat,
                    completion: completion
                )
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
    
    private func insertChatIntoDatabase(
        chat: Chat,
        completion: @escaping (Result<Chat, Error>) -> Void
    ) {
        let ref = Database.database().reference()
        let groupChild = ref.child("chats/\(chat.id)")
        groupChild.setValue(chat.toDict) { (error, ref) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            completion(.success(chat))
        }
    }
}
