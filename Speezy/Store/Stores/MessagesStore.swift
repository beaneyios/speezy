//
//  MessagesStore.swift
//  Speezy
//
//  Created by Matt Beaney on 06/03/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation

class MessagesStore {
    private let messageFetcher = MessageFetcher()
    private var messageListeners = [MessageListener]()
    
    private(set) var messages = [Chat: [Message]]()
    private var noMoreMessages = false
    
    private var observations = [ObjectIdentifier : MessagesObservation]()
    private let serialQueue = DispatchQueue(label: "com.speezy.messages")
    
    private var loading = false
    
    func clear() {
        self.messages = [:]
        self.observations = [:]
    }
    
    func fetchNextPage(
        chat: Chat,
        chatters: [Chatter],
        queryCount: UInt
    ) {
        guard
            !noMoreMessages,
            !loading
        else {
            return
        }
        
        loading = true
        messageFetcher.fetchMessages(
            chat: chat,
            chatters: chatters,
            queryCount: queryCount,
            mostRecentMessage: messages[chat]?.last
        ) { (result) in
            self.serialQueue.async {
                switch result {
                case let .success(newMessages):
                    if newMessages.count == 1 && self.messageExists(id: newMessages[0].id) {
                        self.noMoreMessages = true
                    }
                    
                    let oldMessages = self.messages[chat]
                    self.handleNewPage(chat: chat, newMessages: newMessages)
                    
                    // This is the first load and we've now processed the the first page.
                    // So now we can start listening for additions, knowing that the first addition
                    // will be a duplicate, but will get processed.
                    if oldMessages == nil {
                        self.listenForNewMessages(
                            mostRecentMessage: newMessages.first,
                            chat: chat,
                            chatters: chatters
                        )
                    }
                    
                    self.loading = false
                case .failure:
                    break
                }
            }
        }
    }
    
    func listenForNewMessages(
        mostRecentMessage: Message?,
        chat: Chat,
        chatters: [Chatter]
    ) {
        let listener: MessageListener = self.listener(
            chat: chat,
            chatters: chatters
        )
        
        listener.listenForNewMessages(mostRecentMessage: mostRecentMessage) { (result) in
            self.serialQueue.async {
                switch result {
                case let .success(newMessage):
                    self.handleMessageAdded(message: newMessage, chat: chat)
                case let .failure(error):
                    break
                }
            }
        }
        
        messageListeners = messageListeners.replacing(listener)
    }
    
    func listenForDeletedMessages(chat: Chat, chatters: [Chatter]) {
        let listener: MessageListener = self.listener(
            chat: chat,
            chatters: chatters
        )
        
        listener.listenForDeletedMessages { (result) in
            switch result {
            case let .success(messageId):
                self.serialQueue.async {
                    self.handleMessageRemoved(messageId: messageId)
                    guard self.messages[chat]?.index(messageId) == 0 else {
                        return                        
                    }
                    
                    self.listenForNewMessages(
                        mostRecentMessage: self.mostRecentMessage(chat: chat),
                        chat: chat,
                        chatters: chatters
                    )
                }
            case let.failure(error):
                break
            }
        }
    }
    
    private func handleNewPage(chat: Chat, newMessages: [Message]) {
        let messages = self.messages[chat] ?? []
        let mergedMessages = messages.appending(elements: newMessages)
        self.messages[chat] = mergedMessages

        notifyObservers(
            change: .pagedMessages(
                chatId: chat.id,
                newMessages: newMessages,
                allMessages: mergedMessages
            )
        )
    }
    
    private func handleMessageAdded(message: Message, chat: Chat) {
        guard
            let messages = messages[chat],
            !allMessages.contains(message)
        else {
            return
        }

        self.messages[chat] = messages.appending(element: message)
        notifyObservers(
            change: .messageAdded(chatId: chat.id, message: message)
        )
    }
    
    private func handleMessageRemoved(messageId: String) {
        guard
            let chat = self.chat(forMessageId: messageId),
            let message = message(for: messageId),
            let messages = self.messages[chat]
        else {
            return
        }
        
        self.messages[chat] = messages.removing(messageId)
        
        notifyObservers(
            change: .messageRemoved(chatId: chat.id, message: message)
        )
    }
    
    var allMessages: [Message] {
        messages.flatMap {
            $0.value
        }
    }
    
    private func chat(forMessageId id: String) -> Chat? {
        messages.first {
            $0.value.contains(elementWithId: id)
        }.map {
            $0.key
        }
    }
    
    private func message(for id: String) -> Message? {
        allMessages.first {
            $0.id == id
        }
    }
    
    private func messageExists(id: String) -> Bool {
        message(for: id) != nil
    }
    
    private func listener(chat: Chat, chatters: [Chatter]) -> MessageListener {
        messageListeners.first { $0.chat.id == chat.id } ?? MessageListener(chat: chat, chatters: chatters)
    }
    
    private func mostRecentMessage(chat: Chat) -> Message? {
        messages[chat]?.first
    }
}

extension MessagesStore {
    enum Change {
        case messageAdded(chatId: String, message: Message)
        case messageRemoved(chatId: String, message: Message)
        case pagedMessages(chatId: String, newMessages: [Message], allMessages: [Message])
        case initialMessages(chatId: String, messages: [Message])
    }
    
    func addMessagesObserver(_ observer: MessagesObserver, chat: Chat) {
        serialQueue.async {
            let id = ObjectIdentifier(observer)
            self.observations[id] = MessagesObservation(observer: observer)
            
            // We might be mid-load, let's give the new subscriber what we have so far.
            observer.initialMessages(chatId: chat.id, messages: self.messages[chat] ?? [])
        }
    }
    
    func removeMessagesObserver(_ observer: MessagesObserver) {
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
            case let .messageAdded(chatId, message):
                observer.messageAdded(chatId: chatId, message: message)
            case let .messageRemoved(chatId, message):
                observer.messageRemoved(chatId: chatId, message: message)
            case let .pagedMessages(chatId, newMessages, allMessages):
                observer.pagedMessages(chatId: chatId, newMessages: newMessages, allMessages: allMessages)
            case let .initialMessages(chatId, messages):
                observer.initialMessages(chatId: chatId, messages: messages)
            }
        }
    }
}
