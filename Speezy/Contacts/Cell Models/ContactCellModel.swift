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
    
    init(contact: Contact) {
        self.contact = contact
    }
}

extension ContactCellModel {
    var titleText: String {
        contact.displayName
    }
    
    var accountImage: UIImage? {
        UIImage(named: "account-btn")
    }
}

