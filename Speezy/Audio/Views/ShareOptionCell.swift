//
//  ShareOptionCell.swift
//  Speezy
//
//  Created by Matt Beaney on 22/08/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import UIKit

struct ShareOption {
    enum Platform {
        case messenger
        case whatsapp
        case email
        case speezy
    }
    
    let title: String
    let image: UIImage?
    let platform: Platform
}

class ShareOptionCell: UICollectionViewCell, NibLoadable {

    @IBOutlet weak var imgView: UIImageView!
    @IBOutlet weak var lblTitle: UILabel!
    
    func configure(with option: ShareOption) {
        imgView.image = option.image
        lblTitle.text = option.title
    }
}
