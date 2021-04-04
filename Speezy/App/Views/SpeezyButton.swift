//
//  SpeezyButton.swift
//  Speezy
//
//  Created by Matt Beaney on 28/07/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

class SpeezyButton: UIButton {
    private var spinner: UIActivityIndicatorView?
    private var image: UIImage?
    private var isLoading: Bool = false
    
    func startLoading(
        color: UIColor = .white,
        style: UIActivityIndicatorView.Style = .large
    ) {
        if isLoading {
            return
        }

        isEnabled = false
        isLoading = true
        
        image = imageView?.image
        
        setImage(nil, for: .normal)
        
        let spinner = UIActivityIndicatorView(style: style)
        spinner.color = color
        spinner.startAnimating()
        addSubview(spinner)
        
        spinner.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
        
        self.spinner = spinner
    }
    
    func stopLoading(image: UIImage? = nil) {
        isEnabled = true
        isLoading = false
        spinner?.stopAnimating()
        spinner?.removeFromSuperview()
        spinner = nil
        
        if let image = image {
            self.image = image
            setImage(image, for: .normal)
        } else {
            setImage(self.image, for: .normal)
        }        
    }
}
