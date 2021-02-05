//
//  ChatSelectionCellModel.swift
//  Speezy
//
//  Created by Matt Beaney on 05/02/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import UIKit

class ChatSelectionCellModel: ChatCellModel {
    let selected: Bool
    
    init(chat: Chat, currentUserId: String?, selected: Bool) {
        self.selected = selected
        
        super.init(chat: chat, currentUserId: currentUserId)
    }
    
    func tickImage(for selected: Bool?) -> UIImage? {
        guard let selected = selected else {
            return nil
        }
        
        return selected ? UIImage(named: "ticked-contact") : UIImage(named: "unticked-contact")
    }
}
