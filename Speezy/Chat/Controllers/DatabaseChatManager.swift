//
//  DatabaseChatManager.swift
//  Speezy
//
//  Created by Matt Beaney on 17/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation
import FirebaseAuth
import FirebaseDatabase

class DatabaseChatManager {
    var currentQuery: DatabaseQuery?
    
    func fetchChatters(
        chat: Chat,
        completion: @escaping (Result<[Chatter], Error>) -> Void
    ) {
        let ref = Database.database().reference()
        let chattersChild: DatabaseReference = ref.child("chatters/\(chat.id)")
        
        chattersChild.observeSingleEvent(of: .value) { (snapshot) in
            guard let result = snapshot.value as? NSDictionary else {
                completion(.success([]))
                return
            }
            
            let chatters: [Chatter] = result.allKeys.compactMap {
                guard
                    let key = $0 as? String,
                    let dict = result[key] as? NSDictionary
                else {
                    return nil
                }
                
                return DatabaseChatParser.parseChatter(key: key, dict: dict)
            }
            
            completion(.success(chatters))
        } withCancel: { (error) in
            completion(.failure(error))
        }
    }
    
    func fetchMessages(
        chat: Chat,
        mostRecentMessage: Message? = nil,
        completion: @escaping (Result<[Message], Error>) -> Void
    ) {
        let ref = Database.database().reference()
        let chatChild: DatabaseReference = ref.child("messages/\(chat.id)")
        
        let query: DatabaseQuery = {
            if let message = mostRecentMessage {
                return chatChild
                    .queryOrderedByKey()
                    .queryEnding(atValue: message.id)
                    .queryLimited(toLast: 5)
            } else {
                return chatChild.queryOrderedByKey().queryLimited(toLast: 5)
            }
        }()
        
        query.observeSingleEvent(of: .value) { (snapshot) in
            guard let result = snapshot.value as? NSDictionary else {
                completion(.success([]))
                return
            }
            
            let messages: [Message] = result.allKeys.compactMap {
                guard
                    let key = $0 as? String,
                    let dict = result[key] as? NSDictionary
                else {
                    return nil
                }
                
                return DatabaseChatParser.parseMessage(chat: chat, key: key, dict: dict)
            }.sorted {
                $0.sent > $1.sent
            }.filter {
                $0 != mostRecentMessage
            }
            
            completion(.success(messages))
        } withCancel: { (error) in
            completion(.failure(error))
        }
    }
    
    func listenForNewMessages(
        mostRecentMessage: Message?,
        chat: Chat,
        completion: @escaping (Result<Message, Error>) -> Void
    ) {
        currentQuery?.removeAllObservers()
        
        let ref = Database.database().reference()
        let messagesChild: DatabaseReference = ref.child("messages/\(chat.id)")
        currentQuery = messagesChild.queryOrderedByKey().queryLimited(toLast: 1)

        currentQuery?.observe(.childAdded) { (snapshot) in
            guard let result = snapshot.value as? NSDictionary else {
                // TODO: handle error
                assertionFailure("Snapshot not dictionary")
                return
            }
            
            let message = DatabaseChatParser.parseMessage(
                chat: chat,
                key: snapshot.key,
                dict: result
            )
            
            if let message = message {
                if message != mostRecentMessage {
                    completion(.success(message))
                } else {
                    // Do nothing, we don't want to have duplicated messages.
                }
            } else {
                // TODO: Handle parse failure
                assertionFailure("Parsing failed")
            }
        }
    }
    
    func insertMessage(
        item: AudioItem,
        message: Message,
        chat: Chat,
        completion: @escaping (Result<Message, Error>) -> Void
    ) {
        var messageDict: [String: Any] = [
            "audio_id": item.id,
            "duration": item.calculatedDuration,
            "sent_date": message.sent.timeIntervalSince1970
        ]
        
        if let messageText = message.message {
            messageDict["message"] = messageText
        }
        
        if let remoteUrl = item.remoteUrl {
            messageDict["audio_url"] = remoteUrl.absoluteString
        }
        
        if let attachmentUrl = item.attachmentUrl {
            messageDict["attachment_url"] = attachmentUrl
        }
        
        if let userId = Auth.auth().currentUser?.uid {
            messageDict["user_id"] = userId
        }
        
        let ref = Database.database().reference()
        let chatChild = ref.child("messages/\(chat.id)")
        let newMessageChild = chatChild.childByAutoId()
        newMessageChild.setValue(messageDict) { (error, newRef) in
            completion(.success(message))
        }
    }
}

// MARK: Chats
extension DatabaseChatManager {
    func createChat(
        title: String,
        currentChatter: Chatter,
        contacts: [Contact],
        completion: @escaping (Result<Chat, Error>) -> Void
    ) {
        // Convert contacts to chatters and create a group
        var chatters = contacts.map {
            Chatter(
                id: $0.userId,
                displayName: $0.displayName,
                profileImageUrl: $0.profilePhotoUrl
            )
        }
        
        chatters.append(currentChatter)
        
        self.createChatters(chatters: chatters) { (result) in
            switch result {
            case let .success(chatId):
                self.createChat(
                    chatId: chatId,
                    chatters: chatters,
                    title: title,
                    completion: completion
                )
            case let .failure(error):
                break
            }
        }
    }
    
    private func createChatters(
        chatters: [Chatter],
        completion: @escaping (Result<String, Error>) -> Void
    ) {
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
            
            completion(.success(key))
        }
    }
    
    func updateChat(
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
    
    private func createChat(
        chatId: String,
        chatters: [Chatter],
        title: String,
        completion: @escaping (Result<Chat, Error>) -> Void
    ) {
        let chat = Chat(
            id: chatId,
            chatters: chatters,
            title: title,
            lastUpdated: Date().timeIntervalSince1970,
            lastMessage: "New chat started",
            chatImageUrl: nil
        )
        
        updateChat(chat: chat) { (result) in
            switch result {
            case let .success(chat):
                self.addChatToUsersLists(
                    chat: chat,
                    chatters: chatters,
                    completion: completion
                )
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
    
    private func addChatToUsersLists(
        chat: Chat,
        chatters: [Chatter],
        completion: @escaping (Result<Chat, Error>) -> Void
    ) {
        let ref = Database.database().reference()
        let group = DispatchGroup()
        chatters.forEach {
            group.enter()
            
            let userChild = ref.child("users/\($0.id)/chats/\(chat.id)")
            userChild.setValue(true) { (error, ref) in
                // TODO: Consider how to handle errors here.
                group.leave()
            }
        }
        
        group.notify(queue: DispatchQueue.global()) {
            completion(.success(chat))
        }
    }
    
    func fetchChats(
        userId: String,
        completion: @escaping (Result<[Chat], Error>) -> Void
    ) {
        let ref = Database.database().reference()
        let chatsChild: DatabaseReference = ref.child("users/\(userId)/chats")
        let query = chatsChild.queryOrderedByKey()
        query.observeSingleEvent(of: .value) { (snapshot) in
            guard let result = snapshot.value as? NSDictionary else {
                completion(.success([]))
                return
            }
            
            let chatIds: [String] = result.allKeys.compactMap {
                $0 as? String
            }
            
            let chats = self.fetchChats(forChatIds: chatIds) { chats in
                completion(.success(chats))
            }
        } withCancel: { (error) in
            completion(.failure(error))
        }
    }
    
    private func fetchChats(
        forChatIds ids: [String],
        completion: @escaping ([Chat]) -> Void
    ) {
        var chats = [Chat]()
        let group = DispatchGroup()
        
        ids.forEach {
            group.enter()
            let ref = Database.database().reference()
            let chatChild: DatabaseReference = ref.child("chats/\($0)")
            chatChild.observeSingleEvent(of: .value) { (snapshot) in
                guard let result = snapshot.value as? NSDictionary else {
                    group.leave()
                    return
                }
                
                guard let chat = DatabaseChatParser.parseChat(key: snapshot.key, dict: result) else {
                    group.leave()
                    return
                }
                
                chats.append(chat)
                group.leave()
            }
        }
        
        group.notify(queue: DispatchQueue.global()) {
            completion(chats)
        }
    }
}
