//
//  ContactListObserver.swift
//  Speezy
//
//  Created by Matt Beaney on 06/02/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation

protocol ContactListObserver: AnyObject {
    func contactAdded(contact: Contact, in contacts: [Contact])
    func contactUpdated(contact: Contact, in contacts: [Contact])
    func initialContactsReceived(contacts: [Contact])
    func contactRemoved(contact: Contact, contacts: [Contact])
    func allContacts(contacts: [Contact])
}
