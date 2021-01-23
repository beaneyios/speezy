//
//  UITextField+SpeezyGreyPlaceholder.swift
//  Speezy
//
//  Created by Matt Beaney on 23/12/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import UIKit

extension UITextField {
    func makePlaceholderGrey() {
        setPlaceholderTextColor(.speezyDarkGrey)
    }
    
    func setPlaceholderTextColor(_ color: UIColor) {
        guard let placeholder = self.placeholder else {
            return
        }
        
        let attributedPlaceholderText = NSAttributedString(
            string: placeholder,
            attributes: [
                NSAttributedString.Key.foregroundColor: color
            ]
        )
        
        self.attributedPlaceholder = attributedPlaceholderText
    }
}
