//
//  KeyboardConstraintManager.swift
//  Speezy
//
//  Created by Matt Beaney on 21/02/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import UIKit

class KeyboardConstraintManager {
    let view: UIView
    let constraint: NSLayoutConstraint
    let defaultConstant: CGFloat
        
    init(view: UIView, constraint: NSLayoutConstraint, defaultConstant: CGFloat) {
        self.view = view
        self.constraint = constraint
        self.defaultConstant = defaultConstant
    }
    
    func startListening() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(
            self,
            selector: #selector(adjustForKeyboard),
            name: UIResponder.keyboardWillHideNotification, object: nil
        )
        
        notificationCenter.addObserver(
            self,
            selector: #selector(adjustForKeyboard),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
        
        let dismissGesture = UITapGestureRecognizer(
            target: self,
            action: #selector(dismissKeyboard)
        )
        
        view.addGestureRecognizer(dismissGesture)
    }
    
    func stopListening() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.removeObserver(self)
    }
    
    @objc func adjustForKeyboard(notification: Notification) {
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }

        let keyboardScreenEndFrame = keyboardValue.cgRectValue
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)

        if notification.name == UIResponder.keyboardWillHideNotification {
            constraint.constant = defaultConstant
        } else {
            constraint.constant = keyboardViewEndFrame.height - view.safeAreaInsets.bottom + defaultConstant
        }
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}
