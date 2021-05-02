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
    func contactsCoordinator(
        _ coordinator: ContactsCoordinator,
        didLoadExistingChat chat: Chat
    )
    func contactsCoordinator(
        _ coordinator: ContactsCoordinator,
        didStartNewChatWithContact contact: Contact
    )
}

class ContactsCoordinator: ViewCoordinator, NavigationControlling {
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
    
    func navigateToContactListView(animated: Bool = true) {
        let viewController = storyboard.instantiateViewController(
            identifier: "ContactListViewController"
        ) as! ContactListViewController
        
        viewController.hidesBottomBarWhenPushed = true
        viewController.delegate = self
        navigationController.pushViewController(viewController, animated: animated)
    }
    
    func navigateToAddContact(contactId: String) {
        navigateToImportContact(contactId: contactId)
    }
    
    private func navigateToNewContact() {
        let viewController = storyboard.instantiateViewController(
            identifier: "NewContactViewController"
        ) as! NewContactViewController
        viewController.delegate = self
        navigationController.present(viewController, animated: true, completion: nil)
    }
    
    private func navigateToImportContact(contactId: String) {
        let viewController = storyboard.instantiateViewController(
            identifier: "ImportContactViewController"
        ) as! ImportContactViewController
        
        viewController.viewModel = ImportContactViewModel(contactId: contactId)
        viewController.delegate = self
        
        navigationController.setNavigationBarHidden(true, animated: false)
        navigationController.present(viewController, animated: true, completion: nil)
    }
    
    private func navigateToContact(contact: Contact) {
        let viewController = storyboard.instantiateViewController(
            identifier: "ContactViewController"
        ) as! ContactViewController
        
        viewController.delegate = self
        viewController.viewModel = ContactViewModel(
            store: Store.shared,
            contact: contact
        )
        navigationController.pushViewController(viewController, animated: true)
    }
}

extension ContactsCoordinator: ContactViewControllerDelegate {
    func contactViewControllerDidTapBack(_ viewController: ContactViewController) {
        navigationController.popViewController(animated: true)
    }
    
    func contactViewController(
        _ viewController: ContactViewController,
        didLoadExistingChat chat: Chat
    ) {
        delegate?.contactsCoordinator(self, didLoadExistingChat: chat)
    }
    
    func contactViewController(
        _ viewController: ContactViewController,
        didStartNewChatWithContact contact: Contact
    ) {
        delegate?.contactsCoordinator(self, didStartNewChatWithContact: contact)
    }
}

extension ContactsCoordinator: ImportContactViewControllerDelegate {
    func importContactViewController(_ viewController: ImportContactViewController, didImportContact contact: Contact) {
        viewController.dismiss(animated: true) {
            self.contactListViewController?.alertContactAdded(contact: contact)
        }
    }
}

extension ContactsCoordinator: ContactListViewControllerDelegate {
    func contactListViewControllerDidFinish(_ viewController: ContactListViewController) {
        delegate?.contactsCoordinatorDidFinish(self)
    }
    
    func contactListViewController(
        _ viewController: ContactListViewController,
        didSelectContact contact: Contact
    ) {
        navigateToContact(contact: contact)
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
    
    func newContactViewControllerDidSelectBack(_ viewController: NewContactViewController) {
        viewController.dismiss(animated: true, completion: nil)
    }
    
    func newContactViewController(_ viewController: NewContactViewController, didCreateContact contact: Contact) {
        viewController.dismiss(animated: true)
    }
}
