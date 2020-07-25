//
//  UIButton+Disable.swift
//  Speezy
//
//  Created by Matt Beaney on 25/07/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import UIKit

extension UIButton {
    func disable() {
        isEnabled = false
        alpha = 0.5
    }
    
    func enable() {
        isEnabled = true
        alpha = 1.0
    }
}
