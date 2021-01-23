//
//  ChatCell.swift
//  Speezy
//
//  Created by Matt Beaney on 23/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import UIKit

class ChatCell: UICollectionViewCell, NibLoadable {
    @IBOutlet weak var chatTitleLabel: UILabel!
    @IBOutlet weak var lastMessageLabel: UILabel!
    @IBOutlet weak var lastUpdatedLabel: UILabel!

    func configure(item: ChatCellModel) {
        chatTitleLabel.text = item.titleText
        lastMessageLabel.text = item.lastMessageText
        lastUpdatedLabel.text = item.lastUpdatedText
    }
}
