//
//  AudioItemListCoordinator.swift
//  Speezy
//
//  Created by Matt Beaney on 04/02/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation
import UIKit

protocol AudioItemListCoordinatorDelegate: AnyObject {
    func audioItemCoordinatorDidFinishRecording(_ coordinator: AudioItemListCoordinator)
    func audioItemCoordinatorDidFinish(_ coordinator: AudioItemListCoordinator)
}

class AudioItemListCoordinator: ViewCoordinator, NavigationControlling {
    let storyboard = UIStoryboard(name: "Audio", bundle: nil)
    let navigationController: UINavigationController
    
    weak var delegate: AudioItemListCoordinatorDelegate?
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    override func start() {
        navigationController.setNavigationBarHidden(true, animated: false)
        navigateToAudioItemList()
    }
    
    override func finish() {
        delegate?.audioItemCoordinatorDidFinish(self)
    }
    
    func navigateToAudioItem(item: AudioItem) {
        let coordinator = AudioItemCoordinator(navigationController: navigationController)
        add(coordinator)
        coordinator.delegate = self
        coordinator.navigateToAudioItem(item: item)
    }
    
    private func navigateToNewItem() {
        let id = UUID().uuidString
        let item = AudioItem(
            id: id,
            path: "\(id).\(AudioConstants.fileExtension)",
            title: "",
            date: Date(),
            tags: []
        )
        navigateToAudioItem(item: item)
    }
}

extension AudioItemListCoordinator: AudioItemCoordinatorDelegate {
    func audioItemCoordinator(_ coordinator: AudioItemCoordinator, didSaveItem item: AudioItem) {
        listViewController?.saveItem(item)
    }
    
    func audioItemCoordinator(_ coordinator: AudioItemCoordinator, shouldSendItem item: AudioItem) {
        listViewController?.saveItem(item)
        navigateToPublish(item: item)
    }
    
    func audioItemCoordinatorDidFinish(_ coordinator: AudioItemCoordinator) {
        remove(coordinator)
    }
}

extension AudioItemListCoordinator {
    var listViewController: AudioItemListViewController? {
        navigationController.viewControllers.first {
            $0 is AudioItemListViewController
        } as? AudioItemListViewController
    }
}

extension AudioItemListCoordinator: AudioItemListViewControllerDelegate {
    func audioItemListViewControllerDidFinishRecording(_ viewController: AudioItemListViewController) {
        delegate?.audioItemCoordinatorDidFinishRecording(self)
    }
    
    func audioItemListViewControllerDidSelectBack(_ viewController: AudioItemListViewController) {
        navigationController.popViewController(animated: true)
        delegate?.audioItemCoordinatorDidFinish(self)
    }
    
    func audioItemListViewControllerDidSelectCreateNewItem(_ viewController: AudioItemListViewController) {
        navigateToNewItem()
    }
    
    func audioItemListViewController(_ viewController: AudioItemListViewController, didSelectAudioItem item: AudioItem) {
        navigateToAudioItem(item: item)
    }
    
    func audioItemListViewController(_ viewController: AudioItemListViewController, didSelectSendOnItem item: AudioItem) {
        navigateToPublish(item: item)
    }
    
    private func navigateToAudioItemList() {
        guard let viewController = storyboard.instantiateViewController(identifier: "AudioItemListViewController") as? AudioItemListViewController else {
            return
        }

        viewController.delegate = self
        navigationController.pushViewController(viewController, animated: true)
    }
}

extension AudioItemListCoordinator: PublishViewControllerDelegate {
    private func navigateToPublish(item: AudioItem) {
        guard let viewController = storyboard.instantiateViewController(identifier: "PublishViewController") as? PublishViewController else {
            return
        }
        
        let audioManager = AudioManager(item: item)
        viewController.audioManager = audioManager
        viewController.delegate = self
        navigationController.pushViewController(viewController, animated: true)
    }
    
    func publishViewController(_ viewController: PublishViewController, didSaveItemToDrafts item: AudioItem) {
        listViewController?.saveItem(item)
    }
    
    func publishViewControllerShouldNavigateHome(_ viewController: PublishViewController) {
        if viewController.navigationController == self.navigationController {
            self.navigationController.popViewController(animated: true)
        } else {
            viewController.navigationController?.dismiss(animated: true, completion: nil)
        }
    }
    
    func publishViewControllerShouldNavigateBack(_ viewController: PublishViewController) {
        viewController.navigationController?.popViewController(animated: true)
    }
}
