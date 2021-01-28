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
        case loaded
        case loading(Bool)
    }
    
    private(set) var items = [ChatCellModel]()
    var didChange: ((Change) -> Void)?
    
    var shouldShowEmptyView: Bool {
        items.isEmpty
    }
    
    func listenForData() {
        guard let userId = Auth.auth().currentUser?.uid else {
            assertionFailure("No user id")
            return
        }
        
        didChange?(.loading(true))
        ChatListFetcher().fetchChats(userId: userId) { (result) in
            switch result {
            case let .success(chats):
                self.items = chats.map {
                    ChatCellModel(chat: $0)
                }
                
                self.didChange?(.loaded)
            case let .failure(error):
                break
            }
            
            self.didChange?(.loading(false))
        }
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
}
