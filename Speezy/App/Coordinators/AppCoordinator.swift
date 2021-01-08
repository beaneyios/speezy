//
//  AppCoordinator.swift
//  Speezy
//
//  Created by Matt Beaney on 20/07/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import Foundation
import UIKit

class AppCoordinator: ViewCoordinator {
    let navigationController: UINavigationController
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    override func start() {
        navigateToAudioItems()
    }
    
    override func finish() {
        
    }
    
    func showSuccess(message: String) {
        let alert = UIAlertController(title: "Success!", message: message, preferredStyle: .alert)
        navigationController.present(alert, animated: true) {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2.0) {
                alert.dismiss(animated: true, completion: nil)
            }
        }
    }
}

extension AppCoordinator: AudioItemCoordinatorDelegate {
    private func navigateToAudioItems() {
        let coordinator = AudioItemCoordinator(navigationController: navigationController)
        coordinator.delegate = self
        add(coordinator)
        coordinator.start()
    }
    
    func audioItemCoordinatorDidFinish(_ coordinator: AudioItemCoordinator) {
        remove(coordinator)
    }
}
