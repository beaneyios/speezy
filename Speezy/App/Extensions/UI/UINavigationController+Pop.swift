//
//  UINavigationController+Pop.swift
//  Speezy
//
//  Created by Matt Beaney on 23/08/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import UIKit

extension UINavigationController {
    open override func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self as? UIGestureRecognizerDelegate
    }
}
