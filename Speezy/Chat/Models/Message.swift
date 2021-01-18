//
//  Message.swift
//  Speezy
//
//  Created by Matt Beaney on 18/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation

struct Message {
    let chatter: Chatter
    let sent: Date
    
    let message: String?
    let audioUrl: URL?
    let attachmentUrl: URL?
    let duration: TimeInterval?
    
    let readBy: [Chatter]
}
