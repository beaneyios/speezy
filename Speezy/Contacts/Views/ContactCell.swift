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
    
    func configure(item: ContactCellModel) {
        titleLabel.text = item.titleText
        profileImage.image = item.accountImage
    }
}
