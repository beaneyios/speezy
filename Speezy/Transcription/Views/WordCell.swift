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
    
    func configureWithLorem() {
        timer?.invalidate()
        timer = nil
        
        let wordString = Lorem.word
        
        lblTitle.alpha = 0.4
        lblTitle.text = wordString
        lblTitle.textColor = .lightGray
        lblTitle.textAlignment = .center
    }
    
    func runLoremAnimation() {
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false, block: { (timer) in
            let randomNumber = Int.random(in: 0...10)
            if randomNumber > 5 {
                UIView.animate(withDuration: 1.0) {
                    self.lblTitle.alpha = 0.1
                } completion: { _ in
                    self.lblTitle.text = Lorem.word
                    UIView.animate(withDuration: 1.0) {
                        self.lblTitle.alpha = 0.4
                    } completion: { _ in
                        self.runLoremAnimation()
                    }
                }
            } else {
                self.runLoremAnimation()
            }
        })
    }
    
    func configure(with word: Word, isSelected: Bool, fontScale: CGFloat) {
        timer?.invalidate()
        timer = nil
        
        lblTitle.textAlignment = .left
        lblTitle.alpha = 1.0
        lblTitle.text = word.text
        lblTitle.font = UIFont.systemFont(ofSize: 17.0 * fontScale)
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
