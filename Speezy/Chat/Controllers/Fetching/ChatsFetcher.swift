//
//  ChatsFetcher.swift
//  Speezy
//
//  Created by Matt Beaney on 07/03/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation
import FirebaseDatabase

class ChatsFetcher {
    
    func fetchChats(
        userId: String,
        completion: @escaping (Result<[Chat], Error>) -> Void
    ) {
        let ref = Database.database().reference()
        let chatsChild = ref.child("users/\(userId)/chats")
        let query = chatsChild.queryOrderedByKey()
        
        query.observeSingleEvent(of: .value) { (snapshot) in
            guard let result = snapshot.value as? [String: Any] else {
                return
            }
            
            var chats = [Chat]()
            let group = DispatchGroup()
            result.keys.forEach {
                group.enter()
                self.fetchChat(chatId: $0) { result in
                    switch result {
                    case let .success(chat):
                        chats.append(chat)
                    case .failure:
                        break
                    }
                    
                    group.leave()
                }
            }
            
            group.notify(queue: .global()) {
                completion(.success(chats))
            }
        }
    }
    
    private func fetchChat(
        chatId: String,
        completion: @escaping (Result<Chat, Error>) -> Void
    ) {
        let ref = Database.database().reference()
        let chatChild = ref.child("chats/\(chatId)")
        chatChild.observeSingleEvent(of: .value) { (snapshot) in
            guard
                let dict = snapshot.value as? NSDictionary,
                let chat = ChatParser.parseChat(key: snapshot.key, dict: dict)
            else {
                completion(.failure(NSError()))
                return
            }
            
            completion(.success(chat))
        }
    }
}
