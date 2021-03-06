//
//  ChatListViewModel.swift
//  Speezy
//
//  Created by Matt Beaney on 23/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation
import FirebaseAuth

class ChatListViewModel {
    enum Change {
        case replacedItem(Int)
        case loaded
        case loading(Bool)
        case loadChat(Chat)
    }
    
    private(set) var items = [ChatCellModel]()
    private var chats = [Chat]()
    var didChange: ((Change) -> Void)?
    
    private let store: Store
    private let debouncer = Debouncer(seconds: 0.5)
    
    private var awaitingChatId: String?
    
    private(set) var loadingTimerHit = false
    
    var shouldShowEmptyView: Bool {
        items.isEmpty
    }
    
    var userId: String? {
        Auth.auth().currentUser?.uid
    }
    
    var anyUnreadChats: Bool {
        guard let userId = self.userId else {
            return false
        }
        
        return chats.containsUnread(userId: userId)
    }
    
    init(store: Store) {
        self.store = store
    }
    
    func listenForData() {
        guard let userId = userId else {
            assertionFailure("No user id")
            return
        }
        
        didChange?(.loading(true))
        store.chatStore.addChatListObserver(self)
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.0) {
            self.loadingTimerHit = true
            self.didChange?(.loaded)
        }
    }
    
    func navigateToChatId(_ chatId: String) {
        if let chat = chats.first(withId: chatId) {
            didChange?(.loadChat(chat))
        } else {
            didChange?(.loading(true))
            awaitingChatId = chatId
        }
    }
    
    private func updateCellModels(chats: [Chat]) {
        debouncer.debounce {
            self.chats = chats
            self.items = chats.map {
                ChatCellModel(
                    chat: $0,
                    currentUserId: self.userId
                )
            }

            self.didChange?(.loaded)
            self.didChange?(.loading(false))
        }
    }
    
    private func updateCellModelsAndOpenChat(chat: Chat, chats: [Chat]) {
        debouncer.debounce {
            self.chats = chats
            self.items = chats.map {
                ChatCellModel(chat: $0, currentUserId: self.userId)
            }

            self.didChange?(.loaded)
            self.didChange?(.loadChat(chat))
            self.didChange?(.loading(false))
        }
    }
    
    private func updateCellModel(chat: Chat) {
        debouncer.debounce {
            self.chats = self.chats.replacing(chat)
            let newCellModel = ChatCellModel(chat: chat, currentUserId: self.userId)
            self.items = self.items.replacing(newCellModel)
            
            if let index = self.chats.index(chat) {
                self.didChange?(.replacedItem(index))
            } else {
                self.didChange?(.loaded)
            }
        }
    }
}

extension ChatListViewModel: ChatListObserver {
    func chatAdded(chat: Chat, in chats: [Chat]) {
        if let awaitingChatId = awaitingChatId, awaitingChatId == chat.id {
            updateCellModelsAndOpenChat(chat: chat, chats: chats)
        } else {
            updateCellModels(chats: chats)
        }
    }
    
    func chatUpdated(chat: Chat, in chats: [Chat]) {
        if chats.isSameOrderAs(self.chats) {
            updateCellModel(chat: chat)
        } else {
            updateCellModels(chats: chats)
        }
    }
    
    func initialChatsReceived(chats: [Chat]) {
        if let awaitingChatId = awaitingChatId, let chat = chats.first(withId: awaitingChatId) {
            updateCellModelsAndOpenChat(chat: chat, chats: chats)
        } else {
            updateCellModels(chats: chats)
        }
    }
    
    func chatRemoved(chat: Chat, chats: [Chat]) {
        updateCellModels(chats: chats)
    }
}
