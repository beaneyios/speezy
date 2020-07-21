//
//  TagCell.swift
//  Speezy
//
//  Created by Matt Beaney on 21/07/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import UIKit

class TagCell: UICollectionViewCell, NibLoadable {
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var container: UIView!
    
    func configure(with tag: Tag, borderColor: UIColor) {
        lblTitle.text = tag.title
        lblTitle.textColor = borderColor
        
        container.layer.cornerRadius = 8.0
        container.layer.borderWidth = 1.0
        container.layer.borderColor = borderColor.cgColor
    }
}
