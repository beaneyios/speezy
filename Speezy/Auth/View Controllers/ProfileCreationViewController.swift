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
    @IBOutlet weak var aboutYouTxtField: UITextView!
    @IBOutlet weak var completeSignupBtn: UIButton!
    @IBOutlet weak var completeSignupBtnContainer: UIView!
    
    weak var delegate: ProfileCreationViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTextFields()
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
