//
//  ChatSelectionCell.swift
//  Speezy
//
//  Created by Matt Beaney on 05/02/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import UIKit

class ChatSelectionCell: UICollectionViewCell, NibLoadable {

    @IBOutlet weak var chatTitleLabel: UILabel!
    @IBOutlet weak var lastMessageLabel: UILabel!
    @IBOutlet weak var chatImage: UIImageView!
    @IBOutlet weak var chatImageFrame: UIView!
    @IBOutlet weak var tickIcon: UIImageView!
    
    var viewModel: ChatSelectionCellModel?
    
    override var isSelected: Bool {
        didSet {
            configureSelectedTick(selected: isSelected)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        chatImage.layer.cornerRadius = chatImage.frame.width / 2.0
        chatImageFrame.layer.cornerRadius = chatImageFrame.frame.width / 2.0
        chatImageFrame.layer.borderWidth = 1.0
        chatImageFrame.layer.borderColor = UIColor.speezyPurple.cgColor
    }
    
    func configure(item: ChatSelectionCellModel) {
        self.viewModel = item
        
        chatTitleLabel.text = item.titleText
        lastMessageLabel.text = item.lastMessageText
        chatImage.image = nil
        chatImage.alpha = 0.0
        
        item.loadImage { (result) in
            DispatchQueue.main.async {
                switch result {
                case let .success(image):
                    self.chatImage.image = image
                    UIView.animate(withDuration: 1.0) {
                        self.chatImage.alpha = 1.0
                    }
                case .failure:
                    self.chatImage.alpha = 1.0
                    self.chatImage.image = UIImage(named: "account-btn")
                }
            }
        }
    }
    
    private func configureSelectedTick(selected: Bool?) {
        guard let viewModel = self.viewModel else {
            return
        }
        
        tickIcon.image = viewModel.tickImage(for: selected)
    }
}
