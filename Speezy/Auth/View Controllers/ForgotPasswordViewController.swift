//
//  ForgotPasswordViewController.swift
//  Speezy
//
//  Created by Matt Beaney on 14/03/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import UIKit

protocol ForgotPasswordViewControllerDelegate: AnyObject {
    func forgotPasswordViewControllerShouldPop(_ viewController: ForgotPasswordViewController)
}

class ForgotPasswordViewController: UIViewController, FormErrorDisplaying {
    @IBOutlet weak var emailTxtField: UITextField!
    @IBOutlet weak var sendEmailButtonContainer: UIView!
    @IBOutlet weak var lblErrorMessage: UILabel?
    @IBOutlet weak var emailSeparator: UIView!
    
    private var sendEmailButton: GradientButton?
    private var viewModel = ForgotPasswordViewModel()
    
    weak var delegate: ForgotPasswordViewControllerDelegate?
    
    var fieldDict: [Field: UIView] {
        [
            Field.email: emailSeparator
        ]
    }
    
    var separators: [UIView] {
        [emailSeparator]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTextFields()
        sendEmailButtonContainer.addShadow()
        configureButton()
    }
    
    @IBAction func goBack(_ sender: Any) {
        delegate?.forgotPasswordViewControllerShouldPop(self)
    }
    
    private func configureButton() {
        let button = GradientButton.createFromNib()
        sendEmailButtonContainer.addSubview(button)
        button.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
        
        button.configure(title: "SEND EMAIL") {
            self.submit()
        }
        
        self.sendEmailButton = button
    }
    
    private func configureTextFields() {
        [emailTxtField].forEach {
            $0?.makePlaceholderGrey()
            $0?.delegate = self
        }
    }
    
    private func submit() {
        lblErrorMessage?.text = nil
        [emailSeparator].forEach {
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
        
        viewModel.submit { (error) in
            DispatchQueue.main.async {
                if let error = error {
                    self.highlightErroredFields(error: error)
                    return
                } else {
                    let alert = UIAlertController(
                        title: "Please check your email",
                        message: "An email has been sent with a link to reset your password.",
                        preferredStyle: .alert
                    )
                    
                    let action = UIAlertAction(title: "OK", style: .default) { _ in
                        self.delegate?.forgotPasswordViewControllerShouldPop(self)
                    }
                    
                    alert.addAction(action)
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
}

extension ForgotPasswordViewController: UITextFieldDelegate {
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
        default:
            break
        }
        
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case emailTxtField:
            submit()
        default:
            break
        }
        
        return false
    }
}
