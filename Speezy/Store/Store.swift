//
//  StoreController.swift
//  Speezy
//
//  Created by Matt Beaney on 30/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation

class Store {
    static let shared = Store()
    let chatStore = ChatStore()
    
    func listenForChatChanges(userId: String) {
        chatStore.listenForChats(userId: userId)
    }
}
