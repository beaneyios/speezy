//
//  EmailLoginViewController.swift
//  Speezy
//
//  Created by Matt Beaney on 08/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import UIKit
import FirebaseAuth

protocol LoginViewControllerDelegate: AnyObject {
    func loginViewControllerDidLogIn(
        _ viewController: LoginViewController
    )
    func loginViewControllerDidGoBack(
        _ viewController: LoginViewController
    )
}

class LoginViewController: UIViewController, FormErrorDisplaying {
    @IBOutlet weak var facebookLoginBtn: SpeezyButton!
    @IBOutlet weak var txtFieldEmail: UITextField!
    @IBOutlet weak var emailSeparator: UIView!
    @IBOutlet weak var txtFieldPassword: UITextField!
    @IBOutlet weak var passwordSeparator: UIView!
    @IBOutlet weak var loginBtnContainer: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var lblErrorMessage: UILabel!
    
    weak var delegate: LoginViewControllerDelegate?
    private var loginBtn: GradientButton?
    private var insetManager: KeyboardInsetManager!
    
    private let emailViewModel = EmailLoginViewModel()
    
    var fieldDict: [Field : UIView] {
        [
            Field.email: emailSeparator,
            Field.password: passwordSeparator
        ]
    }
    
    var separators: [UIView] {
        [emailSeparator, passwordSeparator]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureTextFields()
        loginBtnContainer.addShadow()
        configureInsetManager()
        configureButton()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        loginBtnContainer.layer.cornerRadius = loginBtnContainer.frame.height / 2.0
        loginBtnContainer.clipsToBounds = true
    }
    
    @IBAction func signInWithFacebook(_ sender: Any) {
        facebookLoginBtn.startLoading(color: UIColor(named: "speezy-purple")!)
        let viewModel = FacebookLoginViewModel()
        viewModel.login(viewController: self) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self.delegate?.loginViewControllerDidLogIn(self)
                case let .failure(error):
                    self.presentError(error: error)
                }
                
                self.facebookLoginBtn.stopLoading()
            }
        }
    }
    
    @IBAction func signInWithApple(_ sender: Any) {
    }
    
    @IBAction func joinNowTapped(_ sender: Any) {
    }
    
    @IBAction func goBack(_ sender: Any) {
        delegate?.loginViewControllerDidGoBack(self)
    }
    
    private func configureButton() {
        let button = GradientButton.createFromNib()
        loginBtnContainer.addSubview(button)
        button.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
        
        button.configure(title: "SIGN IN") {
            self.submit()
        }
        
        self.loginBtn = button
    }
    
    private func submit() {
        clearHighlightedFields()
        if let error = emailViewModel.validationError() {
            highlightErroredFields(error: error)
            return
        }
        
        loginBtn?.startLoading()
        emailViewModel.login { (result) in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self.delegate?.loginViewControllerDidLogIn(self)
                case let .failure(error):
                    self.highlightErroredFields(error: error)
                }
                
                self.loginBtn?.stopLoading()
            }
        }
    }
    
    private func configureTextFields() {
        [txtFieldEmail, txtFieldPassword].forEach {
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
    
    private func presentError(error: AuthError?) {
        guard let error = error else {
            return
        }
        
        let alert = UIAlertController(
            title: "Something went wrong, please try again",
            message: error.message,
            preferredStyle: .alert
        )
        
        let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(ok)
        present(alert, animated: true, completion: nil)
    }
}

extension LoginViewController: UITextFieldDelegate {
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
        case txtFieldEmail:
            emailViewModel.email = newString
        case txtFieldPassword:
            emailViewModel.password = newString
        default:
            break
        }
        
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case txtFieldEmail:
            txtFieldPassword.becomeFirstResponder()
        case txtFieldPassword:
            break
        default:
            break
        }
        
        return false
    }
}
