//
//  NibLoadable.swift
//  Speezy
//
//  Created by Matt Beaney on 21/07/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import Foundation
import UIKit

protocol NibLoadable {
    static func createFromNib() -> Self
    static var nib: UINib { get }
}

extension NibLoadable where Self: UIView {
    static var nib: UINib {
        return UINib(nibName: String(describing: Self.self), bundle: nil)
    }
    
    static func createFromNib() -> Self {
        guard let template = Bundle.main.loadNibNamed(String(describing: Self.self), owner: nil, options: nil)?.first as? Self else {
            fatalError("Tried to load a nib that does not exist.")
        }
        
        return template
    }
}
