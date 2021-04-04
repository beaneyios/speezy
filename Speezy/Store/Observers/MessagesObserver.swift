//
//  MessagesObserver.swift
//  Speezy
//
//  Created by Matt Beaney on 06/03/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation

protocol MessagesObserver: AnyObject {    
    func messageAdded(chatId: String, message: Message)
    func messageRemoved(chatId: String, message: Message)
    func pagedMessages(chatId: String, newMessages: [Message], allMessages: [Message])
    func initialMessages(chatId: String, messages: [Message])
    func messageChanged(chatId: String, message: Message, change: MessageValueChange)
}
