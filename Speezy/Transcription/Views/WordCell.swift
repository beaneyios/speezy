//
//  WordCell.swift
//  Speezy
//
//  Created by Matt Beaney on 13/09/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import UIKit

class WordCell: UICollectionViewCell, NibLoadable {

    @IBOutlet weak var lblTitle: UILabel!
    
    func configure(with word: Word) {
        lblTitle.text = word.text
    }
}
