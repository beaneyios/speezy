//
//  SpeezyProfileView.swift
//  Speezy
//
//  Created by Matt Beaney on 28/03/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation
import UIKit

class SpeezyProfileViewGenerator {
    static var profileBackgroundColors: [UIColor] {
        [
            .systemRed,
            .systemBlue,
            .systemGray,
            .systemGreen,
            .systemYellow,
            .speezyPurple
        ]
    }
    
    static var randomColor: UIColor {
        let randomNumber = Int.random(in: 0...5)
        return profileBackgroundColors[randomNumber]
    }
    
    static func generateProfileImage(
        character: String,
        color: UIColor?
    ) -> UIImage {
        let view = UIView()
        let label = UILabel()
        label.text = character
        
        view.addSubview(label)
        view.frame = CGRect(x: 0, y: 0, width: 50.0, height: 50.0)
        label.frame = CGRect(x: 0, y: 0, width: 50.0, height: 50.0)
        label.textColor = .white
        label.textAlignment = .center
        label.font = UIFont.boldSystemFont(ofSize: 26.0)
        
        if let color = color {
            view.backgroundColor = color
        } else {
            view.backgroundColor = randomColor
        }
        
        return view.asImage()
    }
}
