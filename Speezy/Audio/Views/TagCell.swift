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
    
    func configure(with tag: Tag, foregroundColor: UIColor, backgroundColor: UIColor) {
        lblTitle.text = tag.title
        lblTitle.textColor = foregroundColor
        
        container.layer.cornerRadius = 17.0
        container.layer.borderWidth = 1.0
        container.layer.borderColor = foregroundColor.cgColor
        container.backgroundColor = backgroundColor
    }
}
