//
//  ChatViewModel.swift
//  Speezy
//
//  Created by Matt Beaney on 14/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import UIKit
import FirebaseAuth

class ChatViewModel {
    enum Change {
        case loaded
        case itemInserted(MessageCellModel)
    }
    
    typealias ChangeBlock = (Change) -> Void
    var didChange: ChangeBlock?
    private(set) var items = [MessageCellModel]()
    
    let chatManager = DatabaseChatManager()
    
    func listenForData() {
        
        let chat = Chat(
            id: "chat_1",
            chatters: [
                Chatter(id: "3ewM8SgRjJZz3me76vlEzvz1fKH3", displayName: "Matt", profileImage: nil),
                Chatter(id: "12345", displayName: "Terry", profileImage: nil),
            ],
            title: "Chat 1"
        )
        
        let currentUserId = Auth.auth().currentUser?.uid ?? ""
        
        chatManager.fetchMessages(chat: chat) { (result) in
            switch result {
            case let .success(messages):
                self.items = messages.map {
                    MessageCellModel(
                        message: $0,
                        chat: chat,
                        currentUserId: currentUserId
                    )
                }
                
                self.didChange?(.loaded)
            case let .failure(error):
                break
            }
        }
    }
}
