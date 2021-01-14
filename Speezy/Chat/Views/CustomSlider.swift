//
//  CustomSlider.swift
//  Speezy
//
//  Created by Matt Beaney on 14/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import UIKit

class CustomSlider: UISlider {

    @IBInspectable var trackHeight: CGFloat = 3
    @IBInspectable var thumbRadius: CGFloat = 10
    @IBInspectable var depressedThumbRadius: CGFloat = 12
    @IBInspectable var thumbColour = UIColor.white
    @IBInspectable var borderColor = UIColor.white

    // Custom thumb view which will be converted to UIImage
    // and set as thumb. You can customize it's colors, border, etc.
    private lazy var thumbView: UIView = {
        let thumb = UIView()
        return thumb
    }()

    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    func configure() {
        let thumb = thumbImage(radius: thumbRadius, colour: thumbColour)
        let depressedThumb = thumbImage(radius: depressedThumbRadius, colour: thumbColour)
        setThumbImage(thumb, for: .normal)
        setThumbImage(depressedThumb, for: .highlighted)
    }

    private func thumbImage(radius: CGFloat, colour: UIColor) -> UIImage {
        // Set proper frame
        // y: radius / 2 will correctly offset the thumb

        thumbView.frame = CGRect(x: 0, y: radius / 2, width: radius, height: radius)
        thumbView.layer.cornerRadius = radius / 2
        thumbView.backgroundColor = colour
        thumbView.layer.borderColor = borderColor.cgColor
        thumbView.layer.borderWidth = 0.5

        // Convert thumbView to UIImage
        // See this: https://stackoverflow.com/a/41288197/7235585

        let renderer = UIGraphicsImageRenderer(bounds: thumbView.bounds)
        return renderer.image { rendererContext in
            thumbView.layer.render(in: rendererContext.cgContext)
        }
    }

    override func trackRect(forBounds bounds: CGRect) -> CGRect {
        // Set custom track height
        // As seen here: https://stackoverflow.com/a/49428606/7235585
        var newRect = super.trackRect(forBounds: bounds)
        newRect.size.height = trackHeight
        return newRect
    }

}
