//
//  Chatter.swift
//  Speezy
//
//  Created by Matt Beaney on 18/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import UIKit

struct Chatter: Equatable, Identifiable {
    var id: String
    var displayName: String
    var profileImageUrl: URL?
    var pushToken: String?
}

extension Chatter {
    var toDict: [String: Any] {
        var dict = [String: Any]()
        dict["display_name"] = displayName
        
        if let profileImageUrl = profileImageUrl {
            dict["profile_image_url"] = profileImageUrl.absoluteString
        }
        
        if let pushToken = pushToken {
            dict["push_token"] = pushToken
        }
        
        return dict
    }
}

extension Array where Element == Chatter {
    var toDict: [String: Any] {
        var dict = [String: Any]()
        
        forEach {
            dict[$0.id] = $0.toDict
        }
        
        return dict
    }
    
    func readChatters(forMessageDate date: Date, chat: Chat) -> [Chatter] {
        filter {
            guard let readBy = chat.readBy[$0.id] else {
                return false
            }
            
            return readBy >= date.timeIntervalSince1970
        }
    }
    
    func chatter(for id: String) -> Chatter? {
        first { $0.id == id }
    }
}
