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
    func audioItemCoordinator(_ coordinator: AudioItemCoordinator, didSaveItem item: AudioItem)
    func audioItemCoordinator(_ coordinator: AudioItemCoordinator, shouldSendItem item: AudioItem, saveFirst: Bool)
    func audioItemCoordinator(_ coordinator: AudioItemCoordinator, shouldDiscardItem item: AudioItem)
}

class AudioItemCoordinator: ViewCoordinator, NavigationControlling {
    let storyboard = UIStoryboard(name: "Audio", bundle: nil)
    let navigationController: UINavigationController
    
    weak var delegate: AudioItemCoordinatorDelegate?
    
    private var modalNavigationController: UINavigationController? {
        navigationController.presentedViewController as? UINavigationController
    }
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    override func start() {
        // no op
    }
    
    override func finish() {
        delegate?.audioItemCoordinatorDidFinish(self)
    }
    
    func navigateToAudioItem(item: AudioItem, playbackOnly: Bool) {
        if playbackOnly {
            navigateToAudioPlayback(item: item)
        } else {
            navigateToAudioEditing(item: item)
        }
    }
    
    private func navigateToAudioPlayback(item: AudioItem) {
        navigationController.setNavigationBarHidden(true, animated: false)
        
        guard let viewController = storyboard.instantiateViewController(identifier: "AudioPlaybackViewController") as? AudioPlaybackViewController else {
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
    
    private func navigateToAudioEditing(item: AudioItem) {
        navigationController.setNavigationBarHidden(true, animated: false)
        
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
    
    private func navigateToTranscription(manager: AudioManager, on pushingViewController: UIViewController) {
        let storyboard = UIStoryboard(name: "Transcription", bundle: nil)
        guard let viewController = storyboard.instantiateViewController(identifier: "transcription") as? TranscriptionViewController else {
            return
        }
        
        viewController.audioManager = manager
        pushingViewController.navigationController?.pushViewController(viewController, animated: true)
    }
    
    private func navigateToCutView(audioItem: AudioItem, on pushingViewController: UIViewController) {
                
        let storyboard = UIStoryboard(name: "Edit", bundle: nil)
        let viewController = storyboard.instantiateViewController(
            identifier: "cut"
        ) as! CutViewController

        let manager = AudioManager(item: audioItem)
        viewController.manager = manager
        viewController.delegate = self
        pushingViewController.navigationController?.present(viewController, animated: true, completion: nil)
    }
    
    private func navigateToInsertView(
        audioItem: AudioItem,
        preRecordedItem: AudioItem,
        on pushingViewController: UIViewController
    ) {
        let storyboard = UIStoryboard(name: "Edit", bundle: nil)
        let viewController = storyboard.instantiateViewController(
            identifier: "FileInserterViewController"
        ) as! FileInserterViewController
        
        let manager = AudioManager(item: audioItem)
        viewController.manager = manager
        viewController.fileToInsert = preRecordedItem
        viewController.delegate = self
        pushingViewController.present(
            viewController,
            animated: true,
            completion: nil
        )
    }
    
    private func navigateToPreRecordedList(
        originalAudioItem item: AudioItem,
        on pushingViewController: UIViewController
    ) {
        let storyboard = UIStoryboard(name: "Edit", bundle: nil)
        let viewController = storyboard.instantiateViewController(
            identifier: "PreRecordListViewController"
        ) as! PreRecordListViewController
        
        let viewModel = PreRecordListViewModel(originalAudioItem: item)
        
        viewController.viewModel = viewModel
        viewController.delegate = self
        pushingViewController.navigationController?.present(
            viewController,
            animated: true,
            completion: nil
        )
    }
    
    private func navigateToCropView(audioItem: AudioItem, on pushingViewController: UIViewController) {
        let storyboard = UIStoryboard(name: "Edit", bundle: nil)
        guard let viewController = storyboard.instantiateViewController(identifier: "crop") as? CropViewController else {
            return
        }
        
        let manager = AudioManager(item: audioItem)
        viewController.manager = manager
        viewController.delegate = self
        pushingViewController.navigationController?.present(viewController, animated: true, completion: nil)
    }
}

extension AudioItemCoordinator: FileInserterViewControllerDelegate {
    func fileInserterViewController(
        _ viewController: FileInserterViewController,
        didFinishInsertionOnItem item: AudioItem
    ) {
        viewController.presentingViewController?.presentingViewController?.dismiss(
            animated: true)
        {
            let viewControllers = self.modalNavigationController?.viewControllers
            let audioItemViewController = viewControllers?.compactMap {
                $0 as? AudioItemViewController
            }.first
            
            guard
                let itemViewController = audioItemViewController,
                let manager = itemViewController.audioManager
            else {
                return
            }
            
            manager.regeneratePlayer(withItem: manager.currentItem)
            manager.markAsDirty()
            itemViewController.reset()
        }
    }
    
    func fileInserterViewControllerDidTapClose(_ viewController: FileInserterViewController) {
        
    }
}

extension AudioItemCoordinator: CutViewControllerDelegate {
    func cutViewController(_ viewController: CutViewController, didFinishCutFrom from: TimeInterval, to: TimeInterval) {
        guard let navigationController = viewController.presentingViewController as? UINavigationController else {
            assertionFailure("Expecting this to be a nav controller.")
            return
        }
        
        viewController.dismiss(animated: true) {
            let audioItemViewController = navigationController.viewControllers.first {
                $0 is AudioItemViewController
            } as? AudioItemViewController
            
            guard
                let itemViewController = audioItemViewController,
                let manager = itemViewController.audioManager
            else {
                return
            }
            
            manager.regeneratePlayer(withItem: manager.currentItem)
            manager.markAsDirty()
            manager.adjustTranscript(forCutRange: from, to: to)
            audioItemViewController?.reset()
        }
    }
    
    func cutViewControllerDidTapClose(_ viewController: CutViewController) {
        viewController.dismiss(animated: true, completion: nil)
    }
}

extension AudioItemCoordinator: CropViewControllerDelegate {
    func cropViewControllerDidFinishCrop(_ viewController: CropViewController) {
        guard let navigationController = viewController.presentingViewController as? UINavigationController else {
            assertionFailure("Expecting this to be a nav controller.")
            return
        }
        
        viewController.dismiss(animated: true) {
            let audioItemViewController = navigationController.viewControllers.first {
                $0 is AudioItemViewController
            } as? AudioItemViewController
            
            guard
                let itemViewController = audioItemViewController,
                let manager = itemViewController.audioManager
            else {
                return
            }
            
            manager.regeneratePlayer(withItem: manager.currentItem)
            manager.markAsDirty()
            audioItemViewController?.reset()
        }
    }
    
    func cropViewControllerDidTapClose(_ viewController: CropViewController) {
        viewController.dismiss(animated: true, completion: nil)
    }
}

extension AudioItemCoordinator: AudioItemViewControllerDelegate {
    private func navigateToNewItem() {
        let id = UUID().uuidString
        let item = AudioItem(
            id: id,
            path: "\(id).\(AudioConstants.fileExtension)",
            title: "",
            date: Date(),
            tags: []
        )
        navigateToAudioItem(item: item, playbackOnly: false)
    }
        
    func audioItemViewController(_ viewController: AudioItemViewController, shouldSaveItemToDrafts item: AudioItem) {
        viewController.dismiss(animated: true) {
            self.delegate?.audioItemCoordinator(self, didSaveItem: item)
        }
    }
    
    func audioItemViewController(
        _ viewController: AudioItemViewController,
        shouldSendItem item: AudioItem,
        saveFirst: Bool
    ) {
        viewController.dismiss(animated: true) {
            self.delegate?.audioItemCoordinator(self, shouldSendItem: item, saveFirst: saveFirst)
        }
    }
    
    func audioItemViewController(
        _ viewController: AudioItemViewController,
        shouldDiscardItem item: AudioItem
    ) {
        viewController.dismiss(animated: true) {
            self.delegate?.audioItemCoordinator(self, shouldDiscardItem: item)
        }
    }
    
    func audioItemViewController(
        _ viewController: AudioItemViewController,
        didPresentCutOnItem audioItem: AudioItem
    ) {
        navigateToCutView(audioItem: audioItem, on: viewController)
    }
    
    func audioItemViewController(
        _ viewController: AudioItemViewController,
        didPresentCropOnItem audioItem: AudioItem
    ) {
        navigateToCropView(audioItem: audioItem, on: viewController)
    }
    
    func audioItemViewController(
        _ viewController: AudioItemViewController,
        didPresentInsertTrackOnItem audioItem: AudioItem
    ) {
        navigateToPreRecordedList(
            originalAudioItem: audioItem,
            on: viewController
        )
    }
    
    func audioItemViewController(
        _ viewController: AudioItemViewController,
        didSelectTranscribeWithManager manager: AudioManager
    ) {
        navigateToTranscription(manager: manager, on: viewController)
    }
    
    func audioItemViewControllerShouldPop(_ viewController: AudioItemViewController) {
        viewController.dismiss(animated: true, completion: nil)
    }
    
    func audioItemViewControllerDidFinish(_ viewController: AudioItemViewController) {
        delegate?.audioItemCoordinatorDidFinish(self)
    }
}

extension AudioItemCoordinator: PreRecordListViewControllerDelegate {
    func preRecordListViewController(
        _ viewController: PreRecordListViewController,
        didSelectItem item: AudioItem,
        onOriginalItem originalItem: AudioItem
    ) {
        navigateToInsertView(
            audioItem: originalItem,
            preRecordedItem: item,
            on: viewController
        )
    }
}

extension AudioItemCoordinator: AudioPlaybackViewControllerDelegate {
    func audioPlaybackViewControllerDidTapExit(_ viewController: AudioPlaybackViewController) {
        viewController.dismiss(animated: true, completion: nil)
    }
    
    func audioPlaybackViewControllerDidFinish(_ viewController: AudioPlaybackViewController) {
        delegate?.audioItemCoordinatorDidFinish(self)
    }
}
