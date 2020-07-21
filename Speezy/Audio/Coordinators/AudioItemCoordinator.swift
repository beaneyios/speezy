//
//  AudioItemCoordinator.swift
//  Speezy
//
//  Created by Matt Beaney on 20/07/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import Foundation
import UIKit

protocol AudioItemCoordinatorDelegate: AnyObject {
    func audioItemCoordinatorDidFinish(_ coordinator: AudioItemCoordinator)
}

class AudioItemCoordinator: ViewCoordinator {
    let storyboard = UIStoryboard(name: "Audio", bundle: nil)
    let navigationController: UINavigationController
    
    weak var delegate: AudioItemCoordinatorDelegate?
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    override func start() {
        navigateToAudioItemList()
    }
    
    override func finish() {
        delegate?.audioItemCoordinatorDidFinish(self)
    }
}

extension AudioItemCoordinator {
    var listViewController: AudioItemListViewController? {
        navigationController.viewControllers.first {
            $0 is AudioItemListViewController
        } as? AudioItemListViewController
    }
}

extension AudioItemCoordinator: AudioItemViewControllerDelegate {
    private func navigateToNewItem() {
        let id = UUID().uuidString
        let item = AudioItem(
            id: id,
            path: "\(id).m4a",
            title: "No title",
            date: Date(),
            tags: []
        )
        navigateToAudioItem(item: item)
    }
    
    private func navigateToAudioItem(item: AudioItem) {
        guard let viewController = storyboard.instantiateViewController(identifier: "AudioItemViewController") as? AudioItemViewController else {
            return
        }
        
        let audioManager = AudioManager(item: item)
        viewController.audioManager = audioManager
        viewController.delegate = self
        viewController.modalPresentationStyle = .fullScreen
        navigationController.present(viewController, animated: true, completion: nil)
    }
    
    func audioItemViewController(_ viewController: AudioItemViewController, didSaveItem item: AudioItem) {
        listViewController?.reloadItem(item)
    }
    
    func audioItemViewControllerShouldPop(_ viewController: AudioItemViewController) {
        viewController.dismiss(animated: true, completion: nil)
    }
}

extension AudioItemCoordinator: AudioItemListViewControllerDelegate {
    func audioItemListViewControllerDidSelectCreateNewItem(_ viewController: AudioItemListViewController) {
        navigateToNewItem()
    }
    
    func audioItemListViewController(_ viewController: AudioItemListViewController, didSelectAudioItem item: AudioItem) {
        navigateToAudioItem(item: item)
    }
    
    private func navigateToAudioItemList() {
        guard let viewController = storyboard.instantiateViewController(identifier: "AudioItemListViewController") as? AudioItemListViewController else {
            return
        }

        viewController.delegate = self
        navigationController.pushViewController(viewController, animated: true)
    }
}
