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
    @IBOutlet weak var adminLabel: UILabel!
    
    var viewModel: ChatterCellModel?
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        viewModel?.downloadTask?.cancel()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()        
        imageView.layer.cornerRadius = imageView.frame.width / 2.0
    }

    func configure(viewModel: ChatterCellModel) {
        self.viewModel = viewModel
        imageView.alpha = 0.0
        chatterName.text = viewModel.titleText
        adminLabel.isHidden = !viewModel.isAdmin
        viewModel.loadImage { (result) in
            DispatchQueue.main.async {
                switch result {
                case let .success(image):
                    self.imageView.image = image
                    UIView.animate(withDuration: 1.0) {
                        self.imageView.alpha = 1.0
                    }
                case .failure:
                    break
                }
            }
        }
    }
    
}
