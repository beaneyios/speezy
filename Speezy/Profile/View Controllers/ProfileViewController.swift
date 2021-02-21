//
//  ProfileViewController.swift
//  Speezy
//
//  Created by Matt Beaney on 16/02/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import UIKit
import JGProgressHUD

protocol ProfileViewModel {
    var profile: Profile? { get set }
    var profileImageAttachment: UIImage? { get set }
}

class ProfileViewController: UIViewController {
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var profileImg: UIImageView!
    @IBOutlet weak var attachBtn: SpeezyButton!
    @IBOutlet weak var attachBtnWidth: NSLayoutConstraint!
    @IBOutlet weak var attachBtnHeight: NSLayoutConstraint!
    @IBOutlet weak var copyButtonWidth: NSLayoutConstraint!
    
    @IBOutlet weak var usernameTxtField: UITextField!
    @IBOutlet weak var usernameSeparator: UIView!
    
    @IBOutlet weak var nameTxtField: UITextField!
    @IBOutlet weak var occupationTxtField: UITextField!
    @IBOutlet weak var aboutYouPlaceholder: UILabel!
    @IBOutlet weak var aboutYouTxtField: UITextView!
    
    @IBOutlet weak var lblErrorMessage: UILabel?

    @IBOutlet weak var copyButton: UIButton!
    @IBOutlet weak var usernameIcon: UILabel!
    
    var viewModel: ProfileViewModel!
    var canEditUsername = true
    
    private var insetManager: KeyboardInsetManager!
    private var completeSignupBtn: GradientButton?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureTextView()
        configureTextFields()
        configureInsetManager()
        configureProfileImage()
        configureAboutYouPlaceholder()
        
        if !canEditUsername {
            copyButtonWidth.constant = 25.0
            usernameIcon.textColor = .lightGray
            usernameTxtField.textColor = .lightGray
            usernameTxtField.isUserInteractionEnabled = false
        } else {
            copyButtonWidth.constant = 0.0
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        profileImg.layer.cornerRadius = profileImg.frame.width / 2.0
        attachBtn.layer.cornerRadius = attachBtn.frame.width / 2.0
        attachBtn.layer.borderWidth = 2.0
        attachBtn.layer.borderColor = UIColor.white.cgColor
    }
    
    override func willMove(toParent parent: UIViewController?) {
        super.willMove(toParent: parent)
        
        if parent == nil {
            insetManager.stopListening()
        }
    }
    
    @IBAction func copyUsernameToClipboard(_ sender: Any) {
        
        copyButton.setImage(UIImage(named: "tick-icon"), for: .normal)
        
        let hud = JGProgressHUD()
        hud.textLabel.text = "Copied to clipboard"
        hud.indicatorView = JGProgressHUDSuccessIndicatorView()
        hud.style = .dark
        hud.show(in: self.view)
        
        guard let profile = viewModel.profile else {
            return
        }
        
        UIPasteboard.general.string = profile.userName
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.5) {
            hud.dismiss()
            self.copyButton.setImage(UIImage(named: "copy-button"), for: .normal)
        }
    }
    
    @IBAction func attachProfileImage(_ sender: Any) {
        showAttachmentAlert()
    }
    
    private func configureInsetManager() {
        self.insetManager = KeyboardInsetManager(
            view: view,
            scrollView: scrollView
        )
        
        self.insetManager.startListening()
    }
    
    private func configureAboutYouPlaceholder() {
        aboutYouPlaceholder.text = "About you"
        
        if let profile = viewModel.profile, profile.aboutYou.isEmpty {
            aboutYouPlaceholder.isHidden = false
        } else {
            aboutYouPlaceholder.isHidden = true
        }
    }
    
    private func configureTextFields() {
        nameTxtField.makePlaceholderGrey()
        nameTxtField.delegate = self
        nameTxtField.text = viewModel.profile?.name ?? ""
        
        usernameTxtField.text = viewModel.profile?.userName ?? ""
        usernameTxtField.makePlaceholderGrey()
        usernameTxtField.delegate = self
        
        occupationTxtField.text = viewModel.profile?.occupation ?? ""
        occupationTxtField.makePlaceholderGrey()
        occupationTxtField.delegate = self
        
        configureAboutYouPlaceholder()
    }
    
    private func configureTextView() {
        aboutYouTxtField.delegate = self
        aboutYouTxtField.text = viewModel.profile?.aboutYou
    }
    
    private func configureProfileImage() {
        attachBtn.startLoading(color: .lightGray, style: .medium)
        attachBtn.imageView?.contentMode = .scaleAspectFill
        
        let imageApplication: (UIImage?) -> Void = { image in
            self.attachBtn.stopLoading()
            self.attachBtn.setImage(UIImage(named: "camera-button"), for: .normal)
            self.profileImg.image = image
            
            self.attachBtnWidth.constant = image != nil ? 40.0 : 100.0
            self.attachBtnHeight.constant = image != nil ? 40.0 : 100.0
            
            UIView.animate(withDuration: 0.6) {
                self.attachBtn.setNeedsLayout()
                self.attachBtn.layoutIfNeeded()
            }
        }
        
        imageApplication(viewModel.profileImageAttachment)
    }
}

extension ProfileViewController: UITextViewDelegate {
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        scrollView.scrollRectToVisible(textView.frame, animated: true)
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
        
        if textView == aboutYouTxtField {
            viewModel.profile?.aboutYou = updatedText
            configureAboutYouPlaceholder()
        }
        
        return true
    }
}

extension ProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    private func showAttachmentAlert() {
        let alert = UIAlertController(
            title: "Select your photo",
            message: "From where you want to pick this image?",
            preferredStyle: .actionSheet
        )
        
        let cameraAction = UIAlertAction(title: "Camera", style: .default) { action in
            self.getImage(fromSourceType: .camera)
        }
        
        let photoAlbumAction = UIAlertAction(title: "Photo Album", style: .default) { action in
            self.getImage(fromSourceType: .photoLibrary)
        }
        
        alert.addAction(cameraAction)
        alert.addAction(photoAlbumAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    private func getImage(fromSourceType sourceType: UIImagePickerController.SourceType) {
        //Check is source type available
        if UIImagePickerController.isSourceTypeAvailable(sourceType) {
            let imagePickerController = UIImagePickerController()
            imagePickerController.delegate = self
            imagePickerController.sourceType = sourceType
            attachBtn.startLoading(color: .lightGray, style: .medium)
            self.present(imagePickerController, animated: true, completion: nil)
        }
    }
    
    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
    ) {
        dismiss(animated: true) { [weak self] in
            guard let self = self else {
                return
            }
            
            guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else {
                return
            }
            
            self.viewModel.profileImageAttachment = image
            self.configureProfileImage()
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        attachBtn.stopLoading()
        picker.dismiss(animated: true, completion: nil)
    }
}

extension ProfileViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        scrollView.scrollRectToVisible(textField.frame, animated: true)
    }
    
    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        let currentText = textField.text ?? ""
        let updatedText = (currentText as NSString).replacingCharacters(
            in: range,
            with: string
        )
        
        switch textField {
        case nameTxtField:
            viewModel.profile?.name = updatedText
        case occupationTxtField:
            viewModel.profile?.occupation = updatedText
        case usernameTxtField:
            viewModel.profile?.userName = updatedText
        default:
            break
        }
        
        return true
    }
}

extension ProfileViewController: FormErrorDisplaying {
    var fieldDict: [Field: UIView] {
        [
            Field.username: usernameSeparator
        ]
    }
    
    var separators: [UIView] {
        [usernameSeparator]
    }
}
