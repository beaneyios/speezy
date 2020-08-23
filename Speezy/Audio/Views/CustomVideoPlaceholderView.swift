//
//  CustomVideoPlaceholderView.swift
//  Speezy
//
//  Created by Matt Beaney on 28/07/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import Foundation
import UIKit

class CustomVideoPlaceholderView: UIView, NibLoadable {
    
    @IBOutlet weak var imgAttachment: UIImageView!
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var lblTags: UILabel!
    
    func configure(with item: AudioItem, config: ShareConfig) {
        lblTitle.text = item.title
        let finalString = item.tags.map {
            "#\($0.title), "
        }.joined()
        
        let trimmed = finalString.trimmingCharacters(in: CharacterSet(arrayLiteral: ",", " "))
        lblTags.text = trimmed
        
        imgAttachment.image = config.attachment
        
        lblTags.isHidden = config.includeTags == false
        lblTitle.isHidden = config.includeTitle == false
    }
}
