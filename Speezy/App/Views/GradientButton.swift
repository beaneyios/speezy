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
    
    typealias Action = () -> Void
    var action: Action?
    
    func configure(
        title: String,
        titleColor: UIColor = .white,
        backgroundImage: UIImage? = UIImage(named: "red-gradient"),
        action: @escaping Action
    ) {
        self.button.setTitle(title, for: .normal)
        self.action = action
        self.spinner.isHidden = true
        self.gradientImg.image = backgroundImage
        self.button.setTitleColor(titleColor, for: .normal)
        self.spinner.color = titleColor
        self.spinner.tintColor = titleColor
        
        button.addTarget(
            self,
            action: #selector(buttonTapped),
            for: .touchUpInside
        )
    }
    
    @objc func buttonTapped() {
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
