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
        navigationController.setNavigationBarHidden(true, animated: false)
        navigateToAudioItemList()
    }
    
    override func finish() {
        delegate?.audioItemCoordinatorDidFinish(self)
    }
    
    private func navigateToTranscription(manager: AudioManager, on pushingViewController: UIViewController) {
        let storyboard = UIStoryboard(name: "Transcription", bundle: nil)
        guard let viewController = storyboard.instantiateViewController(identifier: "transcription") as? TranscriptionViewController else {
            return
        }
        
        viewController.audioManager = manager
        pushingViewController.navigationController?.pushViewController(viewController, animated: true)
    }
    
    private func navigateToCutView(audioItem: AudioItem, on pushingViewController: UIViewController) {
        let storyboard = UIStoryboard(name: "Cut", bundle: nil)
        guard let viewController = storyboard.instantiateViewController(identifier: "cut") as? CutViewController else {
            return
        }
        
        let manager = AudioManager(item: audioItem)
        viewController.manager = manager
        viewController.delegate = self
        pushingViewController.navigationController?.present(viewController, animated: true, completion: nil)
    }
}

extension AudioItemCoordinator {
    var listViewController: AudioItemListViewController? {
        navigationController.viewControllers.first {
            $0 is AudioItemListViewController
        } as? AudioItemListViewController
    }
}

extension AudioItemCoordinator: CutViewControllerDelegate {
    func cutViewControllerDidFinishCut(_ viewController: CutViewController) {
        guard let navigationController = viewController.presentingViewController as? UINavigationController else {
            assertionFailure("Expecting this to be a nav controller.")
            return
        }
        
        viewController.dismiss(animated: true) {
            let audioItemViewController = navigationController.viewControllers.first {
                $0 is AudioItemViewController
            } as? AudioItemViewController
            
            audioItemViewController?.audioManager.hasUnsavedChanges = true
            audioItemViewController?.configureSubviews()
        }
    }
    
    func cutViewControllerDidTapClose(_ viewController: CutViewController) {
        viewController.dismiss(animated: true, completion: nil)
    }
}

extension AudioItemCoordinator: AudioItemViewControllerDelegate {
    private func navigateToNewItem() {
        let id = UUID().uuidString
        let item = AudioItem(
            id: id,
            path: "\(id).wav",
            title: "",
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
        let navigationController = UINavigationController(rootViewController: viewController)
        navigationController.modalPresentationStyle = .fullScreen
        navigationController.setNavigationBarHidden(true, animated: false)
        self.navigationController.present(navigationController, animated: true, completion: nil)
    }
    
    func audioItemViewController(_ viewController: AudioItemViewController, didPresentCutOnItem audioItem: AudioItem) {
        navigateToCutView(audioItem: audioItem, on: viewController)
    }
    
    func audioItemViewController(_ viewController: AudioItemViewController, didSaveItemToDrafts item: AudioItem) {
        listViewController?.reloadItem(item)
    }
    
    func audioItemViewController(_ viewController: AudioItemViewController, shouldSendItem item: AudioItem) {
        listViewController?.reloadItem(item)
        navigateToPublish(item: item, on: viewController)
    }
    
    func audioItemViewControllerShouldPop(_ viewController: AudioItemViewController) {
        viewController.dismiss(animated: true, completion: nil)
    }
    
    func audioItemViewController(_ viewController: AudioItemViewController, didSelectTranscribeWithManager manager: AudioManager) {
        navigateToTranscription(manager: manager, on: viewController)
    }
    
    func audioItemViewControllerIsTopViewController(_ viewController: AudioItemViewController) -> Bool {
        viewController.navigationController?.viewControllers.last == viewController
    }
}

extension AudioItemCoordinator: AudioItemListViewControllerDelegate {    
    func audioItemListViewControllerDidSelectSettings(_ viewController: AudioItemListViewController) {
        let settingsCoordinator = SettingsCoordinator(navigationController: navigationController)
        add(settingsCoordinator)
        settingsCoordinator.start()
    }
    
    func audioItemListViewControllerDidSelectCreateNewItem(_ viewController: AudioItemListViewController) {
        navigateToNewItem()
    }
    
    func audioItemListViewController(_ viewController: AudioItemListViewController, didSelectAudioItem item: AudioItem) {
        navigateToAudioItem(item: item)
    }
    
    func audioItemListViewController(_ viewController: AudioItemListViewController, didSelectSendOnItem item: AudioItem) {
        navigateToPublish(item: item, on: viewController)
    }
    
    private func navigateToAudioItemList() {
        guard let viewController = storyboard.instantiateViewController(identifier: "AudioItemListViewController") as? AudioItemListViewController else {
            return
        }

        viewController.delegate = self
        navigationController.pushViewController(viewController, animated: true)
    }
}

extension AudioItemCoordinator: PublishViewControllerDelegate {
    private func navigateToPublish(item: AudioItem, on pushingViewController: UIViewController) {
        guard let viewController = storyboard.instantiateViewController(identifier: "PublishViewController") as? PublishViewController else {
            return
        }
        
        let audioManager = AudioManager(item: item)
        viewController.audioManager = audioManager
        viewController.delegate = self
        pushingViewController.navigationController?.pushViewController(viewController, animated: true)
    }
    
    func publishViewController(_ viewController: PublishViewController, shouldSendItem item: AudioItem) {
        
    }
    
    func publishViewController(_ viewController: PublishViewController, didSaveItemToDrafts item: AudioItem) {
        listViewController?.reloadItem(item)
        
        let audioViewController = viewController.navigationController?.viewControllers.first { $0 is AudioItemViewController } as? AudioItemViewController
        audioViewController?.audioManager = AudioManager(item: item)
        audioViewController?.configureDependencies()
        audioViewController?.configureSubviews()
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
