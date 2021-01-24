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
    
    var viewModel: ContactCellModel?
    
    override var isSelected: Bool {
        didSet {
            configureSelectedTick(selected: isSelected)
        }
    }
    
    func configure(item: ContactCellModel) {
        self.viewModel = item
        
        titleLabel.text = item.titleText
        profileImage.image = item.accountImage
        tickIcon.isHidden = item.selected == nil
        userNameLabel.text = item.userNameText
        
        configureSelectedTick(selected: item.selected)
    }
    
    private func configureSelectedTick(selected: Bool?) {
        guard let viewModel = self.viewModel else {
            return
        }
        
        tickIcon.image = viewModel.tickImage(for: selected)
    }
}
