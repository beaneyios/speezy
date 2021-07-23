//
//  CommentCell.swift
//  Speezy
//
//  Created by Matt Beaney on 23/07/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import UIKit

class CommentCell: UITableViewCell {

    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var lblUsername: UILabel!
    @IBOutlet weak var lblComment: UILabel!
    @IBOutlet weak var lblDate: UILabel!
    
    func configure(cellModel: CommentCellModel) {
        cellModel.loadImage { (result) in
            DispatchQueue.main.async {
                switch result {
                case let .success(image):
                    self.profileImage.image = image
                    UIView.animate(withDuration: 1.0) {
                        self.profileImage.alpha = 1.0
                    }
                case .failure:
                    self.profileImage.alpha = 1.0
                    self.profileImage.image = UIImage(named: "account-btn")
                }
            }
        }
        
        lblUsername.text = cellModel.displayNameText
        lblComment.text = cellModel.commentText
        lblDate.text = cellModel.dateText
    }
}
