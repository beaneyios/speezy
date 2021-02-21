//
//  KeyboardInsetManager.swift
//  Speezy
//
//  Created by Matt Beaney on 23/12/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import UIKit

class KeyboardScrollViewInsetManager {
    let view: UIView
    let scrollView: UIScrollView
        
    init(view: UIView, scrollView: UIScrollView) {
        self.view = view
        self.scrollView = scrollView
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
            scrollView.contentInset = .zero
        } else {
            scrollView.contentInset = UIEdgeInsets(
                top: 0,
                left: 0,
                bottom: keyboardViewEndFrame.height - view.safeAreaInsets.bottom,
                right: 0
            )
        }

        scrollView.scrollIndicatorInsets = scrollView.contentInset
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}
