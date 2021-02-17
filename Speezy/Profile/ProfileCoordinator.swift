//
//  ProfileCoordinator.swift
//  Speezy
//
//  Created by Matt Beaney on 16/02/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation
import UIKit
import FirebaseAuth

protocol ProfileCoordinatorDelegate: AnyObject {
    func profileCoordinatorDidFinish(_ coordinator: ProfileCoordinator)
}

class ProfileCoordinator: ViewCoordinator, NavigationControlling {
    let storyboard = UIStoryboard(name: "Profile", bundle: nil)
    let navigationController: UINavigationController
    
    weak var delegate: ProfileCoordinatorDelegate?
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    override func start() {
        navigateToProfileView()
    }
    
    override func finish() {
        delegate?.profileCoordinatorDidFinish(self)
    }
    
    private func navigateToProfileView() {
        let viewController = storyboard.instantiateViewController(
            identifier: "ProfileEditViewController"
        ) as! ProfileEditViewController
        viewController.viewModel = ProfileEditViewModel(store: Store.shared)
        viewController.delegate = self
        navigationController.pushViewController(viewController, animated: true)
    }
}

extension ProfileCoordinator: ProfileEditViewControllerDelegate {
    func profileEditViewControllerDidLoadContacts(_ viewController: ProfileEditViewController) {
        let contactsCoordinator = ContactsCoordinator(navigationController: navigationController)
        contactsCoordinator.delegate = self
        add(contactsCoordinator)
        contactsCoordinator.start()
    }
}

extension ProfileCoordinator: ContactsCoordinatorDelegate {
    func contactsCoordinatorDidFinish(_ coordinator: ContactsCoordinator) {
        remove(coordinator)
    }
}
