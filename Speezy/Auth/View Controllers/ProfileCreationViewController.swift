//
//  ProfileCreationViewController.swift
//  Speezy
//
//  Created by Matt Beaney on 23/12/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import UIKit

protocol ProfileCreationViewControllerDelegate: AnyObject {
    func profileCreationViewControllerDidCompleteSignup(_ viewController: ProfileCreationViewController)
    func profileCreationViewControllerDidGoBack(_ viewController: ProfileCreationViewController)
}

class ProfileCreationViewController: UIViewController {
    @IBOutlet weak var profileImg: UIImageView!
    @IBOutlet weak var attachBtn: UIButton!
    @IBOutlet weak var nameTxtField: UITextField!
    @IBOutlet weak var aboutYouPlaceholder: UILabel!
    @IBOutlet weak var aboutYouTxtField: UITextView!
    
    @IBOutlet weak var completeSignupBtn: UIButton!
    @IBOutlet weak var completeSignupBtnContainer: UIView!
    
    weak var delegate: ProfileCreationViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTextFields()
        configureTextView()
        completeSignupBtnContainer.addShadow()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        profileImg.layer.cornerRadius = profileImg.frame.width / 2.0
        attachBtn.layer.cornerRadius = attachBtn.frame.width / 2.0
        completeSignupBtnContainer.layer.cornerRadius = completeSignupBtnContainer.frame.height / 2.0
        completeSignupBtnContainer.clipsToBounds = true
    }
    
    @IBAction func completeSignup(_ sender: Any) {
        delegate?.profileCreationViewControllerDidCompleteSignup(self)
    }
    
    @IBAction func goBack(_ sender: Any) {
        delegate?.profileCreationViewControllerDidGoBack(self)
    }
    
    private func configureTextFields() {
        nameTxtField.makePlaceholderGrey()
    }
}

extension ProfileCreationViewController: UITextViewDelegate {
    private func configureTextView() {
        aboutYouTxtField.delegate = self
        aboutYouPlaceholder.isHidden = false
        aboutYouPlaceholder.text = "About you"
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func textView(
        _ textView: UITextView,
        shouldChangeTextIn range: NSRange,
        replacementText text: String
    ) -> Bool {
        
        let updatedText = (textView.text as NSString).replacingCharacters(
            in: range,
            with: text
        )

        if updatedText.isEmpty {
            aboutYouPlaceholder.isHidden = false
        } else {
            aboutYouPlaceholder.isHidden = true
        }
        
        return true
    }
}
