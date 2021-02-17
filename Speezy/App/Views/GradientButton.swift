//
//  GradientButton.swift
//  Speezy
//
//  Created by Matt Beaney on 01/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import UIKit

class GradientButton: UIView, NibLoadable {
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var gradientImg: UIImageView!
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var buttonIcon: UIImageView!
    @IBOutlet weak var buttonIconWidth: NSLayoutConstraint!
    @IBOutlet weak var buttonIconRightPadding: NSLayoutConstraint!
    
    typealias Action = () -> Void
    var action: Action?
    
    enum Color: String {
        case red = "red-gradient"
        case purple = "purple-gradient"
        case clear = ""
    }
    
    func configure(
        title: String,
        titleColor: UIColor = .white,
        color: Color = .red,
        iconImage: UIImage? = nil,
        action: @escaping Action
    ) {
        self.button.setTitle(title, for: .normal)
        self.action = action
        self.spinner.isHidden = true
        self.gradientImg.image = UIImage(named: color.rawValue)
        self.button.setTitleColor(titleColor, for: .normal)
        self.spinner.color = titleColor
        self.spinner.tintColor = titleColor
        
        if let image = iconImage {
            buttonIcon.tintColor = titleColor
            buttonIcon.image = image
            buttonIconWidth.constant = 25.0
            buttonIconRightPadding.constant = 8.0
        } else {
            buttonIcon.image = nil
            buttonIconWidth.constant = 0.0
            buttonIconRightPadding.constant = 0.0
        }
    }

    @IBAction func buttonTapped(_ sender: Any) {
        action?()
    }
    
    func startLoading() {
        button.isHidden = true
        spinner.isHidden = false
        spinner.startAnimating()
    }
    
    func stopLoading() {
        button.isHidden = false
        spinner.isHidden = true
        spinner.stopAnimating()
    }
}
