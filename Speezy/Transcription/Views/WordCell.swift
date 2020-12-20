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
    
    private var timer: Timer?
    
    override var isSelected: Bool {
        didSet {
            configureWordHighlight(isSelected: isSelected)
        }
    }
    
    func configure(with word: Word, isSelected: Bool, fontScale: CGFloat) {
        timer?.invalidate()
        timer = nil
        
        lblTitle.textAlignment = .left
        lblTitle.alpha = 1.0
        lblTitle.text = word.text
        lblTitle.font = UIFont.systemFont(ofSize: 22.0 * fontScale, weight: .thin)
        configureWordHighlight(isSelected: isSelected)
    }
    
    private func configureWordHighlight(isSelected: Bool) {
        if isSelected {
            let attributeString = NSMutableAttributedString(string: lblTitle.text ?? "")
            attributeString.addAttribute(
                NSAttributedString.Key.strikethroughStyle,
                value: 2,
                range: NSMakeRange(0, attributeString.length)
            )
            
            lblTitle.attributedText = attributeString
            lblTitle.textColor = .lightGray
        } else {
            let previousText = lblTitle.attributedText?.string
            lblTitle.attributedText = nil
            lblTitle.text = previousText
            lblTitle.textColor = .black
        }
    }
    
    func highlightActive() {
        self.lblTitle.textColor = .red
    }
    
    func highlightInactive() {
        self.lblTitle.textColor = .black
    }
}