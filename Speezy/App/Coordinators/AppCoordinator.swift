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
        navigateToAuth()
    }
    
    override func finish() {
        
    }
    
    private func navigateToAudioItems() {
        let coordinator = AudioItemCoordinator(navigationController: navigationController)
        coordinator.delegate = self
        add(coordinator)
        coordinator.start()
    }
    
    private func navigateToAuth() {
        let coordinator = AuthCoordinator(navigationController: navigationController)
        coordinator.delegate = self
        add(coordinator)
        coordinator.start()
    }
}

extension AppCoordinator: AuthCoordinatorDelegate {
    func authCoordinatorDidCompleteLogin(_ coordinator: AuthCoordinator) {
        navigateToAudioItems()
    }
    
    func authCoordinatorDidCompleteSignup(_ coordinator: AuthCoordinator) {
        navigateToAudioItems()
    }
    
    func authCoordinatorDidFinish(_ coordinator: AuthCoordinator) {
        remove(coordinator)
    }
}

extension AppCoordinator: AudioItemCoordinatorDelegate {
    func audioItemCoordinatorDidFinish(_ coordinator: AudioItemCoordinator) {
        remove(coordinator)
    }
}
