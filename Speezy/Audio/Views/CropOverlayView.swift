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
    
    @IBOutlet weak var startTag: UIView!
    @IBOutlet weak var endTag: UIView!
    
    @IBOutlet weak var transparentView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        startTag.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        endTag.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMinXMaxYCorner]
        
        startTag.layer.cornerRadius = 3.0
        endTag.layer.cornerRadius = 3.0
    }
    
    func leftHandlePositionPercentage() -> CGFloat {
        leadingConstraint.constant / frame.width
    }
    
    func rightHandlePositionPercentage() -> CGFloat {
        (frame.width + trailingConstraint.constant) / frame.width
    }
    
    func changeStart(percentage: CGFloat) {
        let startX = frame.width * percentage
        leadingConstraint.constant = startX
        setNeedsLayout()
        layoutIfNeeded()
        
        updateAlpha()
    }
    
    func changeEnd(percentage: CGFloat) {
        let endX = frame.width * percentage
        let endConstraint = frame.width - endX
        trailingConstraint.constant = -endConstraint
        setNeedsLayout()
        layoutIfNeeded()
        
        updateAlpha()
    }
    
    private func updateAlpha() {
        if leadingConstraint.constant == 0 && trailingConstraint.constant == 0 {
            transparentView.alpha = 0.1
        } else {
            transparentView.alpha = 0.15
        }
    }
}
