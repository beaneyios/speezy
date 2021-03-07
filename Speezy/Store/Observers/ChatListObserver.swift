//
//  ChatListObserver.swift
//  Speezy
//
//  Created by Matt Beaney on 30/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation

protocol ChatListObserver: AnyObject {
    func chatsPaged(chats: [Chat])
    func chatAdded(chat: Chat, in chats: [Chat])
    func chatUpdated(chat: Chat, in chats: [Chat])
    func initialChatsReceived(chats: [Chat])
    func chatRemoved(chat: Chat, chats: [Chat])
}
