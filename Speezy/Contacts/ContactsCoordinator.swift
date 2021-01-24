//
//  ContactsCoordinator.swift
//  Speezy
//
//  Created by Matt Beaney on 23/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation
import UIKit
import FirebaseAuth

protocol ContactsCoordinatorDelegate: AnyObject {
    func contactsCoordinatorDidFinish(_ coordinator: ContactsCoordinator)
}

class ContactsCoordinator: ViewCoordinator {
    let storyboard = UIStoryboard(name: "Contacts", bundle: nil)
    let navigationController: UINavigationController
    
    weak var delegate: ContactsCoordinatorDelegate?
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    override func start() {
        navigateToContactListView()
    }
    
    override func finish() {
        delegate?.contactsCoordinatorDidFinish(self)
    }
    
    private func navigateToContactListView() {
        let viewController = storyboard.instantiateViewController(
            identifier: "ContactListViewController"
        ) as! ContactListViewController
        
        viewController.delegate = self
        navigationController.pushViewController(viewController, animated: true)
    }
    
    private func navigateToNewContact() {
        let viewController = storyboard.instantiateViewController(
            identifier: "NewContactViewController"
        ) as! NewContactViewController
        viewController.delegate = self
        navigationController.present(viewController, animated: true, completion: nil)
    }
}

extension ContactsCoordinator: ContactListViewControllerDelegate {
    func contactListViewController(_ viewController: ContactListViewController, didSelectContact contact: Contact) {
        
    }
    
    func contactListViewControllerDidSelectBack(_ viewController: ContactListViewController) {
        navigationController.popViewController(animated: true)
    }
    
    func contactListViewControllerDidSelectNewContact(_ viewController: ContactListViewController) {
        navigateToNewContact()
    }
}

extension ContactsCoordinator: NewContactViewControllerDelegate {    
    var contactListViewController: ContactListViewController? {
        navigationController.viewControllers.compactMap {
            $0 as? ContactListViewController
        }.first
    }
    
    func newContactViewController(_ viewController: NewContactViewController, didCreateContact contact: Contact) {
        viewController.dismiss(animated: true) {
            self.contactListViewController?.insertNewContactItem(contact: contact)
        }
    }
}
