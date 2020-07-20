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
        navigateToAudioItem()
    }
    
    override func finish() {
        delegate?.audioItemCoordinatorDidFinish(self)
    }
}

extension AudioItemCoordinator {
    private func navigateToAudioItem() {
        guard let viewController = storyboard.instantiateViewController(identifier: "AudioItemViewController") as? AudioItemViewController else {
            return
        }
        
        navigationController.pushViewController(viewController, animated: true)
    }
}
