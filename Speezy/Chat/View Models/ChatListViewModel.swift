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
    }
    
    private(set) var items = [ChatCellModel]()
    var didChange: ((Change) -> Void)?
    let chatListManager = DatabaseChatManager()
    
    func listenForData() {
        guard let userId = Auth.auth().currentUser?.uid else {
            assertionFailure("No user id")
            return
        }
        
        chatListManager.fetchChats(userId: userId) { (result) in
            switch result {
            case let .success(chats):
                self.items = chats.map {
                    ChatCellModel(chat: $0)
                }
                
                self.didChange?(.loaded)
            case let .failure(error):
                break
            }
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
