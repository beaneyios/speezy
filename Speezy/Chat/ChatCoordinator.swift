//
//  ChatCoordinator.swift
//  Speezy
//
//  Created by Matt Beaney on 14/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation
import UIKit
import FirebaseAuth

protocol ChatCoordinatorDelegate: AnyObject {
    func chatCoordinatorDidFinish(_ coordinator: ChatCoordinator)
}

class ChatCoordinator: ViewCoordinator {
    let storyboard = UIStoryboard(name: "Chat", bundle: nil)
    let navigationController: UINavigationController
    
    weak var delegate: ChatCoordinatorDelegate?
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    override func start() {
        navigateToChatView()
    }
    
    override func finish() {
        delegate?.chatCoordinatorDidFinish(self)
    }
    
    private func navigateToChatView() {
        let viewController = storyboard.instantiateViewController(
            identifier: "ChatViewController"
        ) as! ChatViewController
        
        navigationController.pushViewController(viewController, animated: true)
    }
}
