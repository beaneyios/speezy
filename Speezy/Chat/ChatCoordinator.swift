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

class ChatCoordinator: ViewCoordinator, NavigationControlling {
    let storyboard = UIStoryboard(name: "Chat", bundle: nil)
    let navigationController: UINavigationController
    
    weak var delegate: ChatCoordinatorDelegate?
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    override func start() {}
    
    func start(withAwaitingChatId chatId: String?) {
        navigateToChatListView(withAwaitingChatId: chatId)
    }
    
    override func finish() {
        delegate?.chatCoordinatorDidFinish(self)
    }
    
    func navigateToChatId(_ chatId: String, message: String) {
        guard let chatViewController = chatViewController else {
            chatListViewController?.navigateToChatId(chatId)
            return
        }
        
        if chatViewController.viewModel.chat.id == chatId {
            return
        }
        
        chatViewController.showNotificationLabel()
    }
    
    private func navigateToChatView(chat: Chat) {
        let viewController = storyboard.instantiateViewController(
            identifier: "ChatViewController"
        ) as! ChatViewController
        
        viewController.hidesBottomBarWhenPushed = true
        viewController.delegate = self
        viewController.viewModel = ChatViewModel(chat: chat)        
        navigationController.pushViewController(viewController, animated: true)
    }
    
    private func navigateToChatListView(withAwaitingChatId chatId: String?) {
        let viewController = storyboard.instantiateViewController(
            identifier: "ChatListViewController"
        ) as! ChatListViewController
        
        viewController.delegate = self
        
        if let chatId = chatId {
            viewController.navigateToChatId(chatId)
        }
        
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

extension ChatCoordinator {
    var chatListViewController: ChatListViewController? {
        navigationController.viewControllers.compactMap {
            $0 as? ChatListViewController
        }.first
    }
    
    var chatViewController: ChatViewController? {
        navigationController.viewControllers.compactMap {
            $0 as? ChatViewController
        }.first
    }
}

extension ChatCoordinator: ChatListViewControllerDelegate {
    func chatListViewControllerDidSelectBack(_ viewController: ChatListViewController) {
        navigationController.popViewController(animated: true)
    }
    
    func chatListViewControllerDidSelectCreateNewChat(_ viewController: ChatListViewController) {
        navigateToNewChat()
    }
    
    func chatListViewController(_ viewController: ChatListViewController, didSelectChat chat: Chat) {
        navigateToChatView(chat: chat)
    }
}

extension ChatCoordinator: ChatViewControllerDelegate {
    func chatViewController(_ viewController: ChatViewController, didSelectEditWithAudioManager manager: AudioManager) {
        let coordinator = AudioItemCoordinator(navigationController: navigationController)
        add(coordinator)
        coordinator.delegate = self
        coordinator.navigateToAudioItem(item: manager.item)
    }
    
    func chatViewControllerDidTapBack(_ viewController: ChatViewController) {
        navigationController.popViewController(animated: true)
    }
}

extension ChatCoordinator: AudioItemCoordinatorDelegate {
    func audioItemCoordinatorDidFinish(_ coordinator: AudioItemCoordinator) {
        remove(coordinator)
    }
    
    func audioItemCoordinator(_ coordinator: AudioItemCoordinator, didSaveItem item: AudioItem) {
        chatViewController?.applyChangesToAudioItem(item)
    }
    
    func audioItemCoordinator(_ coordinator: AudioItemCoordinator, shouldDiscardItem item: AudioItem) {
        chatViewController?.discardAudioItem(item)
    }
    
    func audioItemCoordinator(_ coordinator: AudioItemCoordinator, shouldSendItem item: AudioItem, saveFirst: Bool) {
        chatViewController?.sendEditedAudioItem(item)
    }
}

extension ChatCoordinator: NewChatViewControllerDelegate {
    func newChatViewControllerDidSelectBack(_ viewController: NewChatViewController) {
        viewController.dismiss(animated: true, completion: nil)
    }
    
    func newChatViewController(_ viewController: NewChatViewController, didCreateChat chat: Chat) {        
        viewController.dismiss(animated: true, completion: nil)
    }    
}
