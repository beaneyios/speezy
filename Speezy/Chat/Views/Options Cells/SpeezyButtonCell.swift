//
//  SpeezyButtonCell.swift
//  Speezy
//
//  Created by Matt Beaney on 15/05/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import UIKit

class SpeezyButtonCell: UICollectionViewCell, NibLoadable {
    @IBOutlet weak var buttonContainer: UIView!
    var button: GradientButton!
    
    override func layoutSubviews() {
        buttonContainer.layer.cornerRadius = buttonContainer.frame.height / 2.0
        buttonContainer.clipsToBounds = true
    }
    
    func configure(text: String, action: @escaping () -> Void) {
        let button = GradientButton.createFromNib()
        buttonContainer.addSubview(button)
        button.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
        
        button.configure(title: text) {
            action()
        }
        
        self.button = button
    }
}
