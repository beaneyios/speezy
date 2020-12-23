//
//  SignupViewController.swift
//  Speezy
//
//  Created by Matt Beaney on 23/12/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import UIKit

protocol EmailSignupViewControllerDelegate: AnyObject {
    func emailSignupViewControllerDidMoveOnToProfile(_ viewController: EmailSignupViewController)
    func emailSignupViewControllerDidGoBack(_ viewController: EmailSignupViewController)
}

class EmailSignupViewController: UIViewController {
    
    @IBOutlet weak var emailTxtField: UITextField!
    @IBOutlet weak var passwordTxtField: UITextField!
    @IBOutlet weak var passwordValidateTxtField: UITextField!
    @IBOutlet weak var moveOnBtn: UIButton!
    
    weak var delegate: EmailSignupViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTextFields()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        moveOnBtn.layer.cornerRadius = moveOnBtn.frame.height / 2.0
    }
    
    @IBAction func moveOnToProfile(_ sender: Any) {
        delegate?.emailSignupViewControllerDidMoveOnToProfile(self)
    }
    
    @IBAction func goBack(_ sender: Any) {
        delegate?.emailSignupViewControllerDidGoBack(self)
    }
    
    private func configureTextFields() {
        emailTxtField.makePlaceholderGrey()
        passwordTxtField.makePlaceholderGrey()
        passwordValidateTxtField.makePlaceholderGrey()
    }
}
