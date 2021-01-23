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
        
        
        navigationController.pushViewController(viewController, animated: true)
    }
}
