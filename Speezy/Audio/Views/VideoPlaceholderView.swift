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
    
    func configure(with item: AudioItem) {
        lblTitle.text = item.title
    }
}
