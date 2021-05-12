//
//  ChatOptionsViewModel.swift
//  Speezy
//
//  Created by Matt Beaney on 12/05/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation

class ChatOptionsViewModel {
    var chatters: [Chatter]
    
    init(chatters: [Chatter]) {
        self.chatters = chatters
    }
}
