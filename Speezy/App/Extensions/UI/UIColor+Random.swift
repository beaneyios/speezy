//
//  UIColor+Random.swift
//  Speezy
//
//  Created by Matt Beaney on 02/05/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import UIKit

extension UIColor {
    private static var profileBackgroundColors: [UIColor] {
        [
            .systemRed,
            .systemBlue,
            .systemGray,
            .systemGreen,
            .systemYellow,
            .speezyPurple
        ]
    }
    
    static var random: UIColor {
        let randomNumber = Int.random(in: 0...profileBackgroundColors.count - 1)
        return profileBackgroundColors[randomNumber]
    }
}
