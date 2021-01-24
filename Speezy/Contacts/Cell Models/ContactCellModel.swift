//
//  ContactCellModel.swift
//  Speezy
//
//  Created by Matt Beaney on 23/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import UIKit

struct ContactCellModel {
    let contact: Contact
    let selected: Bool?
    
    init(contact: Contact, selected: Bool?) {
        self.contact = contact
        self.selected = selected
    }
}

extension ContactCellModel {
    var titleText: String {
        contact.displayName
    }
    
    var userNameText: String {
        contact.userName
    }
    
    var accountImage: UIImage? {
        UIImage(named: "account-btn")
    }
    
    func tickImage(for selected: Bool?) -> UIImage? {
        guard let selected = selected else {
            return nil
        }
        
        return selected ? UIImage(named: "ticked-contact") : UIImage(named: "unticked-contact")
    }
}

