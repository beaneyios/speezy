//
//  MessageValue.swift
//  Speezy
//
//  Created by Matt Beaney on 03/04/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation

struct MessageValueChange {
    let messageId: String
    let messageValue: MessageValue
}

enum MessageValue {
    case playedBy(String)
    
    init?(key: String, value: Any) {
        if key == "played_by", let playedBy = value as? String {
            self = .playedBy(playedBy)
        } else {
            return nil
        }
    }
}
