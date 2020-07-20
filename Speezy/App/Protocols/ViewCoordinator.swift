//
//  ViewCoordinator.swift
//  Speezy
//
//  Created by Matt Beaney on 20/07/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import Foundation

class ViewCoordinator {
    var childCoordinators: [ViewCoordinator] = []
    
    func start() {}
    func finish() {}
    
    func add(_ coordinator: ViewCoordinator) {
        childCoordinators.append(coordinator)
    }
    
    func remove(_ coordinator: ViewCoordinator) {
        childCoordinators = childCoordinators.filter { $0 !== coordinator }
    }
}
