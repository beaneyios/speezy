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
        navigateToNewItem()
    }
    
    override func finish() {
        delegate?.audioItemCoordinatorDidFinish(self)
    }
}

extension AudioItemCoordinator {
    private func navigateToNewItem() {
        let id = UUID().uuidString
        guard let url = FileManager.default.documentsOutputURL(with: "\(id).m4a", create: true) else {
            assertionFailure("Unable to create URL for uuid")
            return
        }
        
        let item = AudioItem(id: id, url: url)
        
        navigateToAudioItem(item: item)
    }
    
    private func navigateToAudioItem(item: AudioItem) {
        guard let viewController = storyboard.instantiateViewController(identifier: "AudioItemViewController") as? AudioItemViewController else {
            return
        }
        
        let audioManager = AudioManager(item: item)
        viewController.audioManager = audioManager
        navigationController.pushViewController(viewController, animated: true)
    }
}
