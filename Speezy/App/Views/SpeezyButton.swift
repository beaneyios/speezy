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
    
    func startLoading() {
        if isLoading {
            return
        }

        isEnabled = false
        isLoading = true
        
        image = imageView?.image
        
        setImage(nil, for: .normal)
        
        let spinner = UIActivityIndicatorView(style: .large)
        spinner.color = .white
        spinner.startAnimating()
        addSubview(spinner)
        
        spinner.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
        
        self.spinner = spinner
    }
    
    func stopLoading() {
        isEnabled = true
        isLoading = false
        spinner?.stopAnimating()
        spinner?.removeFromSuperview()
        spinner = nil
        setImage(image, for: .normal)
    }
}
