//
//  CropOverlayView.swift
//  Speezy
//
//  Created by Matt Beaney on 15/08/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import UIKit

class CropOverlayView: UIView, NibLoadable {
    @IBOutlet weak var leadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var trailingConstraint: NSLayoutConstraint!
    
    func changeStart(percentage: CGFloat) {
        let startX = frame.width * percentage
        leadingConstraint.constant = startX
        setNeedsLayout()
        layoutIfNeeded()
    }
    
    func changeEnd(percentage: CGFloat) {
        let endX = frame.width * percentage
        let endConstraint = frame.width - endX
        trailingConstraint.constant = -endConstraint
        setNeedsLayout()
        layoutIfNeeded()
    }
}
