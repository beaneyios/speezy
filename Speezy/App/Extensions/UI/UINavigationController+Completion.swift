//
//  UINavigationController+Completion.swift
//  Speezy
//
//  Created by Matt Beaney on 05/02/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import UIKit

extension UINavigationController {
    func popViewController(animated: Bool, completion: @escaping () -> Void) {
        CATransaction.setCompletionBlock {
            completion()
        }
        
        CATransaction.begin()
        popViewController(animated: true)
        CATransaction.commit()
    }
}
