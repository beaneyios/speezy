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
    
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var lblTags: UILabel!
    
    
    func configure(with item: AudioItem) {
        lblTitle.text = item.title
        let finalString = item.tags.map {
            "#\($0.title), "
        }.joined()
        
        let trimmed = finalString.trimmingCharacters(in: CharacterSet(arrayLiteral: ",", " "))
        lblTags.text = trimmed
    }
}
