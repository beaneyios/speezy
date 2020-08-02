//
//  SettingsCell.swift
//  Speezy
//
//  Created by Matt Beaney on 02/08/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import UIKit

class SettingsCell: UITableViewCell {
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var imgIcon: UIImageView!
    @IBOutlet weak var container: UIView!
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        self.container.backgroundColor = selected ? .systemGray4 : .white
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        self.container.backgroundColor = highlighted ? .systemGray4 : .white
    }
    
    func configure(with item: SettingsItem) {
        imgIcon.image = item.icon
        lblTitle.text = item.title
        imgIcon.tintColor = item.tint
    }
}