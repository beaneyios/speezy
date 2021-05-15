//
//  ChatValue.swift
//  Speezy
//
//  Created by Matt Beaney on 30/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation

struct ChatValueChange {
    let chatId: String
    let chatValue: ChatValue
}

enum ChatValue {
    case lastMessage(String)
    case lastUpdated(TimeInterval)
    case title(String)
    case readBy([String: TimeInterval])
    case pushTokens([String: String])
    case chatters([Chatter])
    
    init?(key: String, value: Any) {
        switch (key, value) {
        case ("last_updated", let value as TimeInterval):
            self = .lastUpdated(value)
        case ("last_message", let value as String):
            self = .lastMessage(value)
        case ("title", let value as String):
            self = .title(value)
        case ("read_by", let value as [String: TimeInterval]):
            self = .readBy(value)
        case ("push_tokens", let value as [String: String]):
            self = .pushTokens(value)
        case ("chatters", let value as [String: Any]):
            let chatters = ChatParser.parseChatters(dict: value as NSDictionary)
            self = .chatters(chatters)
        default:
            return nil
        }
    }
    
    var key: String {
        switch self {
        case .lastMessage:
            return "last_message"
        case .lastUpdated:
            return "last_updated"
        case .title:
            return "title"
        case .readBy:
            return "read_by"
        case .pushTokens:
            return "push_tokens"
        case .chatters:
            return "chatters"
        }
    }
    
    var value: Any {
        switch self {
        case let .lastMessage(message):
            return message
        case let .lastUpdated(timeInterval):
            return timeInterval
        case let .title(title):
            return title
        case let .readBy(readBy):
            return readBy
        case let .pushTokens(tokens):
            return tokens
        case let .chatters(chatters):
            return chatters
        }
    }
}
