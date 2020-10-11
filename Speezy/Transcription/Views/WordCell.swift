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
    
    override var isSelected: Bool {
        didSet {
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
    }
    
    func configure(with word: Word) {
        lblTitle.text = word.text
//        lblTitle.text = "\(word.text) - \(word.timestamp.start) -> \(word.timestamp.end)"
    }
    
    func highlightActive() {
        self.lblTitle.textColor = .red
    }
    
    func highlightInactive() {
        self.lblTitle.textColor = .black
    }
}
