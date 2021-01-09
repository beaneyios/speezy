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

class LoginViewController: UIViewController {
    @IBOutlet weak var txtFieldEmail: UITextField!
    @IBOutlet weak var txtFieldPassword: UITextField!
    @IBOutlet weak var loginBtnContainer: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    weak var delegate: LoginViewControllerDelegate?
    private var loginBtn: GradientButton?
    private var insetManager: KeyboardInsetManager!
    
    private let emailViewModel = EmailLoginViewModel()
    
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
        
        button.configure(title: "SIGN UP") {
            self.submit()
        }
        
        self.loginBtn = button
    }
    
    private func submit() {
        if let error = emailViewModel.validatonError() {
            let alert = UIAlertController(
                title: error.title,
                message: error.message,
                preferredStyle: .alert
            )
            
            let action = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(action)
            present(alert, animated: true, completion: nil)
            return
        }
        
        loginBtn?.startLoading()
        emailViewModel.login { (result) in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self.delegate?.loginViewControllerDidLogIn(self)
                case .failure:
                    break
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
