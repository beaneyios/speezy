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

class EmailSignupViewController: UIViewController {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var emailTxtField: UITextField!
    @IBOutlet weak var passwordTxtField: UITextField!
    @IBOutlet weak var passwordValidateTxtField: UITextField!
    @IBOutlet weak var moveOnBtn: UIButton!
    @IBOutlet weak var moveOnBtnContainer: UIView!
    
    weak var delegate: EmailSignupViewControllerDelegate?
    var viewModel: EmailSignupViewModel!
    private var insetManager: KeyboardInsetManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTextFields()
        moveOnBtnContainer.addShadow()
        configureInsetManager()
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
    
    @IBAction func moveOnToProfile(_ sender: Any) {
        submit()
    }
    
    @IBAction func goBack(_ sender: Any) {
        delegate?.emailSignupViewControllerDidGoBack(self)
    }
    
    private func submit() {
        if let error = viewModel.validatonError() {
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
        
        view.endEditing(true)
        
        viewModel.signup { (result) in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self.delegate?.emailSignupViewController(
                        self,
                        didMoveOnToProfileWithViewModel: self.viewModel
                    )
                case .failure:
                    break
                }
            }
        }
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
