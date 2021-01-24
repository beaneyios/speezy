//
//  ContactCell.swift
//  Speezy
//
//  Created by Matt Beaney on 23/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import UIKit

class ContactCell: UICollectionViewCell, NibLoadable {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var tickIcon: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var profileImageFrame: UIView!
    
    var viewModel: ContactCellModel?
    
    override var isSelected: Bool {
        didSet {
            configureSelectedTick(selected: isSelected)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        profileImage.layer.cornerRadius = profileImage.frame.width / 2.0
        profileImageFrame.layer.cornerRadius = profileImageFrame.frame.width / 2.0
        profileImageFrame.layer.borderWidth = 1.0
        profileImageFrame.layer.borderColor = UIColor.speezyPurple.cgColor
    }
    
    func configure(item: ContactCellModel) {
        self.viewModel = item
        
        titleLabel.text = item.titleText
        tickIcon.isHidden = item.selected == nil
        userNameLabel.text = item.userNameText
        
        configureSelectedTick(selected: item.selected)
        
        
        profileImage.alpha = 0.0
        item.loadImage { (result) in
            DispatchQueue.main.async {
                switch result {
                case let .success(image):
                    self.profileImage.image = image
                    UIView.animate(withDuration: 1.0) {
                        self.profileImage.alpha = 1.0
                    }
                case let .failure(error):
                    self.profileImage.alpha = 1.0
                    self.profileImage.image = UIImage(named: "account-btn")
                }
            }
        }
    }
    
    private func configureSelectedTick(selected: Bool?) {
        guard let viewModel = self.viewModel else {
            return
        }
        
        tickIcon.image = viewModel.tickImage(for: selected)
    }
}
