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
        guard let placeholder = self.placeholder else {
            return
        }
        
        let attributedPlaceholderText = NSAttributedString(
            string: placeholder,
            attributes: [
                NSAttributedString.Key.foregroundColor: UIColor(
                    named: "speezy-grey-text"
                )!
            ]
        )
        
        self.attributedPlaceholder = attributedPlaceholderText
    }
}
