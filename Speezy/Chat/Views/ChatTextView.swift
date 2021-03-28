//
//  ChatTextView.swift
//  Speezy
//
//  Created by Matt Beaney on 28/03/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import UIKit

class ChatTextView: UIView, NibLoadable {
    @IBOutlet weak var txtField: UITextField!
    @IBOutlet weak var activitySpinner: UIActivityIndicatorView!
    @IBOutlet weak var sendButtonIcon: UIButton!
    @IBOutlet weak var sendButtonText: UIButton!
    
    var sendAction: (() -> Void)?
    var cancelAction: (() -> Void)?
    var textChangeAction: ((String) -> Void)?
    
    @IBAction func sendButtonTapped(_ sender: Any) {
        showLoader()
        sendAction?()
    }
    
    @IBAction func cancelTapped(_ sender: Any) {
        cancelAction?()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        txtField.delegate = self
        activitySpinner.isHidden = true
    }
    
    func showLoader() {
        activitySpinner.isHidden = false
        activitySpinner.startAnimating()
        sendButtonIcon.isHidden = true
        sendButtonText.isHidden = true
    }
}

extension ChatTextView: UITextFieldDelegate {
    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        
        guard let textFieldText = textField.text else {
            return true
        }
        
        let nsText = textFieldText as NSString
        let newString = nsText.replacingCharacters(
            in: range,
            with: string
        )
        
        textChangeAction?(newString)
        return true
    }
}
