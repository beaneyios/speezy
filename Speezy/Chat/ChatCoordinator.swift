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
        navigateToChatListView()
    }
    
    override func finish() {
        delegate?.chatCoordinatorDidFinish(self)
    }
    
    private func navigateToChatView(chat: Chat) {
        let viewController = storyboard.instantiateViewController(
            identifier: "ChatViewController"
        ) as! ChatViewController
        
        viewController.delegate = self
        viewController.viewModel = ChatViewModel(chat: chat)        
        navigationController.pushViewController(viewController, animated: true)
    }
    
    private func navigateToChatListView() {
        let viewController = storyboard.instantiateViewController(
            identifier: "ChatListViewController"
        ) as! ChatListViewController
        
        viewController.delegate = self
        navigationController.pushViewController(viewController, animated: true)
    }
    
    private func navigateToNewChat() {
        let viewController = storyboard.instantiateViewController(
            identifier: "NewChatViewController"
        ) as! NewChatViewController
        
        viewController.delegate = self
        navigationController.present(viewController, animated: true, completion: nil)
    }
}

extension ChatCoordinator: ChatListViewControllerDelegate {
    func chatListViewControllerDidSelectCreateNewChat(_ viewController: ChatListViewController) {
        navigateToNewChat()
    }
    
    func chatListViewController(_ viewController: ChatListViewController, didSelectChat chat: Chat) {
        navigateToChatView(chat: chat)
    }
}

extension ChatCoordinator: ChatViewControllerDelegate {
    func chatViewControllerDidTapBack(_ viewController: ChatViewController) {
        navigationController.popViewController(animated: true)
    }
}

extension ChatCoordinator: NewChatViewControllerDelegate {
    var chatListViewController: ChatListViewController? {
        navigationController.viewControllers.compactMap {
            $0 as? ChatListViewController
        }.first
    }
    func newChatViewController(_ viewController: NewChatViewController, didCreateChat chat: Chat) {
        viewController.dismiss(animated: true) {
            guard let chatListViewController = self.chatListViewController else {
                return
            }
            
            chatListViewController.insertNewChatItem(chat: chat)
        }
    }    
}
