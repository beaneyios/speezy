//
//  ChatterCell.swift
//  Speezy
//
//  Created by Matt Beaney on 12/05/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import UIKit
import SwipeCellKit

class ChatterCell: SwipeCollectionViewCell, NibLoadable {
    @IBOutlet weak var chatterName: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    var viewModel: ChatterCellModel?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        imageView.layer.cornerRadius = imageView.frame.width / 2.0
    }

    func configure(viewModel: ChatterCellModel) {
        self.viewModel = viewModel
        imageView.alpha = 0.0
        viewModel.loadImage { (result) in
            DispatchQueue.main.async {
                switch result {
                case let .success(image):
                    self.imageView.image = image
                    UIView.animate(withDuration: 1.0) {
                        self.imageView.alpha = 1.0
                    }
                case let .failure(error):
                    self.imageView.alpha = 1.0
                    self.imageView.image = UIImage(named: "account-btn")
                }
            }
        }
    }
    
}
