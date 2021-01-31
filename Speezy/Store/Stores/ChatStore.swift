//
//  ChatStore.swift
//  Speezy
//
//  Created by Matt Beaney on 30/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation

class ChatStore {
    private let chatListener = ChatsListener()
    private(set) var chats = [Chat]()
    
    private var observations = [ObjectIdentifier : ChatListObservation]()
    private let serialQueue = DispatchQueue(label: "com.speezy.chatStoreActions")
    
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
        
        chatListener.listenForChatAdditions(userId: userId)
        chatListener.listenForChatDeletions(userId: userId)
    }
    
    private func handleChatAdded(chat: Chat) {
        if chats.contains(chat) {
            return
        }
        
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
                let readBy = readBy.components(separatedBy: ",")
                return chatToUpdate?.withReadBy(readBy: readBy)
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
        
        chats = chats.removing(chat)
        sortChats()
        notifyObservers(change: .chatRemoved(chat: chat, chats: chats))
    }
    
    private func replaceChat(chat: Chat) {
        chats = chats.replacing(chat)
    }
    
    private func sortChats() {
        chats = chats.sorted(by: { (chat1, chat2) -> Bool in
            chat1.lastUpdated > chat2.lastUpdated
        })
    }
}

extension ChatStore {
    enum Change {
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
