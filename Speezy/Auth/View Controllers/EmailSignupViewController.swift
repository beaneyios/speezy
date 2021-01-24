//
//  SignupViewController.swift
//  Speezy
//
//  Created by Matt Beaney on 23/12/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import UIKit

protocol EmailSignupViewControllerDelegate: AnyObject {
    func emailSignupViewController(
        _ viewController: EmailSignupViewController,
        didMoveOnToProfileWithViewModel viewModel: EmailSignupViewModel
    )
    func emailSignupViewControllerDidGoBack(_ viewController: EmailSignupViewController)
}

class EmailSignupViewController: UIViewController, FormErrorDisplaying {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var emailTxtField: UITextField!
    @IBOutlet weak var emailSeparator: UIView!
    
    @IBOutlet weak var passwordTxtField: UITextField!
    @IBOutlet weak var passwordSeparator: UIView!
    
    @IBOutlet weak var passwordValidateTxtField: UITextField!
    @IBOutlet weak var passwordValidateSeparator: UIView!
    
    @IBOutlet weak var moveOnBtnContainer: UIView!
    @IBOutlet weak var lblErrorMessage: UILabel?
    
    private var moveOnBtn: GradientButton?
    
    weak var delegate: EmailSignupViewControllerDelegate?
    var viewModel: EmailSignupViewModel!
    private var insetManager: KeyboardInsetManager!
    
    var fieldDict: [Field: UIView] {
        [
            Field.email: emailSeparator,
            Field.password: passwordSeparator,
            Field.passwordVerifier: passwordValidateSeparator
        ]
    }
    
    var separators: [UIView] {
        [emailSeparator, passwordSeparator, passwordValidateSeparator]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTextFields()
        moveOnBtnContainer.addShadow()
        configureInsetManager()
        configureButton()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        moveOnBtnContainer.layer.cornerRadius = moveOnBtnContainer.frame.height / 2.0
        moveOnBtnContainer.clipsToBounds = true
    }

    override func willMove(toParent parent: UIViewController?) {
        super.willMove(toParent: parent)
        
        if parent == nil {
            insetManager.stopListening()
        }
    }
    
    func moveOnToProfile() {
        submit()
    }
    
    @IBAction func goBack(_ sender: Any) {
        delegate?.emailSignupViewControllerDidGoBack(self)
    }
    
    private func submit() {
        lblErrorMessage?.text = nil
        [passwordSeparator, passwordValidateSeparator, emailSeparator].forEach {
            $0?.backgroundColor = UIColor.speezyDarkGrey
            $0?.constraints.forEach {
                if $0.firstAttribute == .height {
                    $0.constant = 0.5
                }
            }
        }
        
        if let error = viewModel.validationError() {
            highlightErroredFields(error: error)
            return
        }
        
        view.endEditing(true)
        delegate?.emailSignupViewController(
            self,
            didMoveOnToProfileWithViewModel: viewModel
        )
    }
    
    private func configureButton() {
        let button = GradientButton.createFromNib()
        moveOnBtnContainer.addSubview(button)
        button.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
        
        button.configure(title: "SIGN UP") {
            self.moveOnToProfile()
        }
        
        self.moveOnBtn = button
    }
    
    private func configureTextFields() {
        [emailTxtField, passwordTxtField, passwordValidateTxtField].forEach {
            $0?.makePlaceholderGrey()
            $0?.delegate = self
        }
    }
    
    private func configureInsetManager() {
        insetManager = KeyboardInsetManager(
            view: view,
            scrollView: scrollView
        )
        
        insetManager.startListening()
    }
}

extension EmailSignupViewController: UITextFieldDelegate {
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
        
        switch textField {
        case emailTxtField:
            viewModel.email = newString
        case passwordTxtField:
            viewModel.password = newString
        case passwordValidateTxtField:
            viewModel.verifyPassword = newString
        default:
            break
        }
        
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case emailTxtField:
            passwordTxtField.becomeFirstResponder()
        case passwordTxtField:
            passwordValidateTxtField.becomeFirstResponder()
        case passwordValidateTxtField:
            submit()
        default:
            break
        }
        
        return false
    }
}
