//
//  ChatShareViewModel.swift
//  Speezy
//
//  Created by Matt Beaney on 05/02/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation
import FirebaseAuth

class ChatShareViewModel {
    enum Change: Equatable {
        case loaded
        case loading(Bool)
        case selectChat(Chat)
    }
    
    private(set) var selectedChats = [Chat]()
    
    private(set) var items = [ChatSelectionCellModel]()
    private var chats = [Chat]()
    var didChange: ((Change) -> Void)?
    
    private let store: Store
    private let audioItem: AudioItem
    
    var shouldShowEmptyView: Bool {
        items.isEmpty
    }
    
    var userId: String? {
        Auth.auth().currentUser?.uid
    }
    
    init(store: Store, audioItem: AudioItem) {
        self.store = store
        self.audioItem = audioItem
    }
    
    func fetchChats() {
        updateCellModels(chats: store.chatStore.chats)
    }
    
    func selectChat(chat: Chat) {
        if let chatIndex = selectedChats.firstIndex(of: chat) {
            selectedChats.remove(at: chatIndex)
        } else {
            selectedChats.append(chat)
        }
    }
    
    private func updateCellModels(chats: [Chat]) {
        self.chats = store.chatStore.chats
        self.items = chats.map {
            ChatSelectionCellModel(
                chat: $0,
                currentUserId: self.userId,
                selected: self.selectedChats.contains($0)
            )
        }

        self.didChange?(.loaded)
        self.didChange?(.loading(false))
    }
}
