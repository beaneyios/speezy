//
//  UIView+AsImage.swift
//  Speezy
//
//  Created by Matt Beaney on 25/07/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import UIKit

extension UIView {
    func asImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { rendererContext in
            layer.render(in: rendererContext.cgContext)
        }
    }
}
