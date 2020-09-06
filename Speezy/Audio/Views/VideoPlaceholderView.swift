//
//  VideoPlaceholderView.swift
//  Speezy
//
//  Created by Matt Beaney on 24/07/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

class VideoPlaceholderView: UIView, NibLoadable {
    
    @IBOutlet weak var attributionHeight: NSLayoutConstraint!
    @IBOutlet weak var lblAttribution: UILabel!
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var lblTags: UILabel!
    
    func configure(with item: AudioItem, config: ShareConfig) {
        lblTitle.text = item.title
        let finalString = item.tags.map {
            "#\($0.title), "
        }.joined()
        
        let trimmed = finalString.trimmingCharacters(in: CharacterSet(arrayLiteral: ",", " "))
        lblTags.text = trimmed
        
        lblTags.isHidden = config.includeTags == false
        lblTitle.isHidden = config.includeTitle == false
    }
}
