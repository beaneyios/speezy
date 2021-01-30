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
    }
    
    private(set) var items = [ChatCellModel]()
    private var chats = [Chat]()
    var didChange: ((Change) -> Void)?
    
    private let store: Store
    private let debouncer = Debouncer(seconds: 0.5)
    
    var shouldShowEmptyView: Bool {
        items.isEmpty
    }
    
    init(store: Store) {
        self.store = store
    }
    
    func listenForData() {
        guard let userId = Auth.auth().currentUser?.uid else {
            assertionFailure("No user id")
            return
        }
        
        didChange?(.loading(true))
        store.chatStore.addChatListObserver(self)
    }
    
    func insertNewChatItem(chat: Chat) {
        let newCellModel = ChatCellModel(chat: chat)
        if items.isEmpty {
            items.append(newCellModel)
        } else {
            items.insert(newCellModel, at: 0)
        }
        
        didChange?(.loaded)
    }
    
    private func updateCellModels(chats: [Chat]) {
        debouncer.debounce {
            self.chats = chats
            self.items = chats.map {
                ChatCellModel(chat: $0)
            }

            self.didChange?(.loaded)
            self.didChange?(.loading(false))
        }
    }
    
    private func updateCellModel(chat: Chat) {
        debouncer.debounce {
            self.chats = self.chats.replacing(chat)
            let newCellModel = ChatCellModel(chat: chat)
            self.items = self.items.replacing(newCellModel)
            
            if let index = self.chats.firstIndex(of: chat) {
                self.didChange?(.replacedItem(index))
            } else {
                self.didChange?(.loaded)
            }
        }
    }
}

extension ChatListViewModel: ChatListObserver {
    func chatAdded(chat: Chat, in chats: [Chat]) {
        updateCellModels(chats: chats)
    }
    
    func chatUpdated(chat: Chat, in chats: [Chat]) {
        if chats.isSameOrderAs(self.chats) {
            updateCellModel(chat: chat)
        } else {
            updateCellModels(chats: chats)
        }
    }
    
    func initialChatsReceived(chats: [Chat]) {
        updateCellModels(chats: chats)
    }
    
    func chatRemoved(chat: Chat, chats: [Chat]) {
        updateCellModels(chats: chats)
    }
}
