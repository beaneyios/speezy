//
//  AudioItemCell.swift
//  Speezy
//
//  Created by Matt Beaney on 21/07/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import UIKit

class AudioItemCell: UITableViewCell {

    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var lblDate: UILabel!
    @IBOutlet weak var btnMoreOptions: UIButton!
    
    func configure(with audioItem: AudioItem) {
        lblTitle.text = audioItem.title
    }
    
    @IBAction func moreOptionsTapped(_ sender: Any) {
        print("More options")
    }
}
