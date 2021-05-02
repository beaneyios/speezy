//
//  ChatStore.swift
//  Speezy
//
//  Created by Matt Beaney on 30/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation

class ChatStore {
    private let chatFetcher = ChatsFetcher()
    private let chatListener = ChatsListener()
    private(set) var chats = [Chat]()
    
    private var observations = [ObjectIdentifier : ChatListObservation]()
    private let serialQueue = DispatchQueue(label: "com.speezy.chatStoreActions")
    
    func clear() {
        self.chatListener.stopListening()
        self.chats = []
        self.observations = [:]
    }
    
    func listenForChats(userId: String) {
        chatListener.didChange = { change in
            // We do not want to manipulate the chats available until the notifier has
            // finished notifying any newly added observers, so we need a queue.
            self.serialQueue.async {
                switch change {
                case let .chatAdded(chat):
                    self.handleChatAdded(chat: chat)
                case let .chatUpdated(change):
                    self.handleChatUpdated(change: change)
                case let .chatRemoved(id):
                    self.handleChatRemoved(chatId: id)
                }
            }
        }
        
        chatFetcher.fetchChats(userId: userId) { (result) in
            switch result {
            case let .success(chats):
                self.chats = chats.sortedByLastUpdated()
                self.notifyObservers(change: .chatsPaged(chats: self.chats))
                
                chats.forEach {
                    self.chatListener.listenForChatChanges(chat: $0)
                }
                
                self.chatListener.listenForChatAdditions(userId: userId)
                self.chatListener.listenForChatDeletions(userId: userId)
            default:
                break
            }
        }
    }
    
    private func handleChatAdded(chat: Chat) {
        if chats.contains(chat) {
            return
        }
        
        chatListener.listenForChatChanges(chat: chat)
        chats.append(chat)
        sortChats()
        notifyObservers(change: .chatAdded(chat: chat, chats: chats))
    }
    
    private func handleChatUpdated(change: ChatValueChange) {
        // Find the chat to update.
        let chatToUpdate = chats.first {
            change.chatId == $0.id
        }
        
        // Apply the change.
        let newChat: Chat? = {
            switch change.chatValue {
            case let .lastMessage(message):
                return chatToUpdate?.withLastMessage(message)
            case let .lastUpdated(lastUpdated):
                return chatToUpdate?.withLastUpdated(lastUpdated)
            case let .title(title):
                return chatToUpdate?.withTitle(title)
            case let .readBy(readBy):
                return chatToUpdate?.withReadBy(readBy: readBy)
            case let .pushTokens(tokens):
                return chatToUpdate?.withPushTokens(tokens: tokens)
            }
        }()
        
        // Replace the old chat with the new one.
        if let newChat = newChat {
            replaceChat(chat: newChat)
            sortChats()
            notifyObservers(change: .chatUpdated(chat: newChat, chats: chats))
        }
    }
    
    private func handleChatRemoved(chatId: String) {
        guard let chat = chats.first(withId: chatId) else {
            return
        }
        
        chats = chats.removing(chat).sortedByLastUpdated()
        notifyObservers(change: .chatRemoved(chat: chat, chats: chats))
    }
    
    private func replaceChat(chat: Chat) {
        chats = chats.replacing(chat)
    }
    
    private func sortChats() {
        chats = chats.sortedByLastUpdated()
    }
}

extension ChatStore {
    enum Change {
        case chatsPaged(chats: [Chat])
        case chatAdded(chat: Chat, chats: [Chat])
        case chatUpdated(chat: Chat, chats: [Chat])
        case initialChats(chats: [Chat])
        case chatRemoved(chat: Chat, chats: [Chat])
    }
    
    func addChatListObserver(_ observer: ChatListObserver) {
        serialQueue.async {
            let id = ObjectIdentifier(observer)
            self.observations[id] = ChatListObservation(observer: observer)
            
            // We might be mid-load, let's give the new subscriber what we have so far.
            observer.initialChatsReceived(chats: self.chats)
        }
    }
    
    func removeChatListObserver(_ observer: ChatListObserver) {
        serialQueue.async {
            let id = ObjectIdentifier(observer)
            self.observations.removeValue(forKey: id)
        }
    }
    
    private func notifyObservers(change: Change) {
        observations.forEach {
            guard let observer = $0.value.observer else {
                observations.removeValue(forKey: $0.key)
                return
            }
            
            switch change {
            case let .chatsPaged(chats):
                observer.chatsPaged(chats: chats)
            case let .chatAdded(chat, chats):
                observer.chatAdded(chat: chat, in: chats)
            case let .chatUpdated(chat, chats):
                observer.chatUpdated(chat: chat, in: chats)
            case let .initialChats(chats):
                observer.initialChatsReceived(chats: chats)
            case let .chatRemoved(chat, chats):
                observer.chatRemoved(chat: chat, chats: chats)
            }
        }
    }
}
