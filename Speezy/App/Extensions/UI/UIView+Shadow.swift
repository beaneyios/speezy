//
//  UIView+Shadow.swift
//  Speezy
//
//  Created by Matt Beaney on 15/07/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    func addShadow(
        opacity: Float = 0.5,
        radius: CGFloat = 2.0,
        offset: CGSize = CGSize(width: 0.0, height: 1.0)
    ) {
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = opacity
        layer.shadowRadius = radius
        layer.shadowOffset = offset
        layer.masksToBounds = false
        layer.rasterizationScale = UIScreen.main.scale
        layer.shouldRasterize = true
    }
    
    func removeShadow() {
        layer.shadowColor = nil
        layer.shadowOffset = .zero
        layer.shadowRadius = 0
        layer.shadowOpacity = 0
        layer.zPosition = 0
    }
}
