//
//  SpeezyLoadingView.swift
//  Speezy
//
//  Created by Matt Beaney on 18/10/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import UIKit

class SpeezyLoadingView: UIView, NibLoadable {
    
    @IBOutlet weak var firstBar: UIView!
    @IBOutlet weak var secondBar: UIView!
    @IBOutlet weak var thirdBar: UIView!
    @IBOutlet weak var fourthBar: UIView!
    
    var firstConstraint: NSLayoutConstraint!
    var secondConstraint: NSLayoutConstraint!
    var thirdConstraint: NSLayoutConstraint!
    var fourthConstraint: NSLayoutConstraint!
    
    var restCompletion: (() -> Void)?
    
    override func awakeFromNib() {
        firstConstraint = firstBar.heightAnchor.constraint(
            equalTo: heightAnchor,
            multiplier: 0.4
        )
        
        secondConstraint = secondBar.heightAnchor.constraint(
            equalTo: heightAnchor,
            multiplier: 1.0
        )
        
        thirdConstraint = thirdBar.heightAnchor.constraint(
            equalTo: heightAnchor,
            multiplier: 0.4
        )
        
        fourthConstraint = fourthBar.heightAnchor.constraint(
            equalTo: heightAnchor,
            multiplier: 0.2
        )
        
        firstConstraint.isActive = true
        secondConstraint.isActive = true
        thirdConstraint.isActive = true
        fourthConstraint.isActive = true
        
        layoutIfNeeded()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        firstBar.layer.cornerRadius = firstBar.frame.width / 2.0
        secondBar.layer.cornerRadius = secondBar.frame.width / 2.0
        thirdBar.layer.cornerRadius = thirdBar.frame.width / 2.0
        fourthBar.layer.cornerRadius = fourthBar.frame.width / 2.0
    }
    
    var shouldAnimate: Bool = false
    func startAnimating() {
        shouldAnimate = true
        animate(outward: true)
    }
    
    func stopAnimating() {
        shouldAnimate = false
    }
    
    func animate(outward: Bool) {
        firstConstraint.isActive = false
        secondConstraint.isActive = false
        thirdConstraint.isActive = false
        fourthConstraint.isActive = false
        
        if outward {
            firstConstraint = firstConstraint.constraintWithMultiplier(1.0)
            secondConstraint = secondConstraint.constraintWithMultiplier(0.2)
            thirdConstraint = thirdConstraint.constraintWithMultiplier(0.5)
            fourthConstraint = fourthConstraint.constraintWithMultiplier(0.8)
        } else {
            firstConstraint = firstConstraint.constraintWithMultiplier(0.4)
            secondConstraint = secondConstraint.constraintWithMultiplier(1.0)
            thirdConstraint = thirdConstraint.constraintWithMultiplier(0.4)
            fourthConstraint = fourthConstraint.constraintWithMultiplier(0.2)
        }
        
        firstConstraint.isActive = true
        secondConstraint.isActive = true
        thirdConstraint.isActive = true
        fourthConstraint.isActive = true
        
        UIView.animate(withDuration: 0.8) {
            self.layoutIfNeeded()
        } completion: { (finished) in
            
            if self.shouldAnimate {
                self.animate(outward: !outward)
            } else {
                self.rest()
            }
        }
    }
    
    func rest() {
        firstConstraint.isActive = false
        secondConstraint.isActive = false
        thirdConstraint.isActive = false
        fourthConstraint.isActive = false
        
        firstConstraint = firstConstraint.constraintWithMultiplier(1.0)
        secondConstraint = secondConstraint.constraintWithMultiplier(1.0)
        thirdConstraint = thirdConstraint.constraintWithMultiplier(1.0)
        fourthConstraint = fourthConstraint.constraintWithMultiplier(1.0)
        
        firstConstraint.isActive = true
        secondConstraint.isActive = true
        thirdConstraint.isActive = true
        fourthConstraint.isActive = true
        
        UIView.animate(withDuration: 0.8) {
            self.layoutIfNeeded()
        } completion: { (finished) in
            self.restCompletion?()
        }

    }
}

extension NSLayoutConstraint {
    func constraintWithMultiplier(_ multiplier: CGFloat) -> NSLayoutConstraint {
        return NSLayoutConstraint(
            item: self.firstItem!,
            attribute: self.firstAttribute,
            relatedBy: self.relation,
            toItem: self.secondItem,
            attribute: self.secondAttribute,
            multiplier: multiplier,
            constant: self.constant
        )
    }
}
