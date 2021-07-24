//
//  UIColor+ConvenienceInit.swift
//  Speezy
//
//  Created by Matt Beaney on 24/07/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import UIKit

extension UIColor {
    static func fromDict(key: String, dict: NSDictionary) -> UIColor {
        if let colorString = dict[key] as? String, let color = UIColor(hex: colorString) {
            return color
        }
        
        return UIColor.random
    }
}
