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
    func audioItemCoordinator(_ coordinator: AudioItemCoordinator, shouldSendItem item: AudioItem)
    func audioItemCoordinator(_ coordinator: AudioItemCoordinator, shouldDiscardItem item: AudioItem)
}

class AudioItemCoordinator: ViewCoordinator, NavigationControlling {
    let storyboard = UIStoryboard(name: "Audio", bundle: nil)
    let navigationController: UINavigationController
    
    weak var delegate: AudioItemCoordinatorDelegate?
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    override func start() {
        // no op
    }
    
    override func finish() {
        delegate?.audioItemCoordinatorDidFinish(self)
    }
    
    func navigateToAudioItem(item: AudioItem) {
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
        let storyboard = UIStoryboard(name: "Cut", bundle: nil)
        guard let viewController = storyboard.instantiateViewController(identifier: "cut") as? CutViewController else {
            return
        }
        
        let manager = AudioManager(item: audioItem)
        viewController.manager = manager
        viewController.delegate = self
        pushingViewController.navigationController?.present(viewController, animated: true, completion: nil)
    }
    
    private func navigateToCropView(audioItem: AudioItem, on pushingViewController: UIViewController) {
        let storyboard = UIStoryboard(name: "Cut", bundle: nil)
        guard let viewController = storyboard.instantiateViewController(identifier: "crop") as? CropViewController else {
            return
        }
        
        let manager = AudioManager(item: audioItem)
        viewController.manager = manager
        viewController.delegate = self
        pushingViewController.navigationController?.present(viewController, animated: true, completion: nil)
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
            
            audioItemViewController?.audioManager.markAsDirty()
            audioItemViewController?.audioManager.adjustTranscript(forCutRange: from, to: to)
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
            
            audioItemViewController?.audioManager.markAsDirty()
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
        navigateToAudioItem(item: item)
    }
        
    func audioItemViewController(_ viewController: AudioItemViewController, shouldSaveItemToDrafts item: AudioItem) {
        viewController.dismiss(animated: true) {
            self.delegate?.audioItemCoordinator(self, didSaveItem: item)
        }
    }
    
    func audioItemViewController(_ viewController: AudioItemViewController, shouldSendItem item: AudioItem) {
        viewController.dismiss(animated: true) {
            self.delegate?.audioItemCoordinator(self, shouldSendItem: item)
        }
    }
    
    func audioItemViewController(_ viewController: AudioItemViewController, shouldDiscardItem item: AudioItem) {
        viewController.dismiss(animated: true) {
            self.delegate?.audioItemCoordinator(self, shouldDiscardItem: item)
        }
    }
    
    func audioItemViewController(_ viewController: AudioItemViewController, didPresentCutOnItem audioItem: AudioItem) {
        navigateToCutView(audioItem: audioItem, on: viewController)
    }
    
    func audioItemViewController(_ viewController: AudioItemViewController, didPresentCropOnItem audioItem: AudioItem) {
        navigateToCropView(audioItem: audioItem, on: viewController)
    }
    
    func audioItemViewController(_ viewController: AudioItemViewController, didSelectTranscribeWithManager manager: AudioManager) {
        navigateToTranscription(manager: manager, on: viewController)
    }
    
    func audioItemViewControllerShouldPop(_ viewController: AudioItemViewController) {
        viewController.dismiss(animated: true, completion: nil)
    }
    
    func audioItemViewControllerDidFinish(_ viewController: AudioItemViewController) {
        delegate?.audioItemCoordinatorDidFinish(self)
    }
}
