//
//  SocialCoordinator.swift
//  Speezy
//
//  Created by Matt Beaney on 04/02/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation
import UIKit

class SocialCoordinator: ViewCoordinator, NavigationControlling {
    let navigationController: UINavigationController
        
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    override func start() {
        navigationController.setNavigationBarHidden(true, animated: false)
        navigateToSocial()
    }
    
    private func navigateToSocial() {
        let viewController = SocialFeedViewController()
        viewController.viewModel = SocialFeedViewModel()
        navigationController.pushViewController(viewController, animated: false)
    }
}

extension SocialCoordinator {
    var listViewController: PostViewController? {
        navigationController.viewControllers.first {
            $0 is PostViewController
        } as? PostViewController
    }
}
