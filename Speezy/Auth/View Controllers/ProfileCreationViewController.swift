//
//  ProfileCreationViewController.swift
//  Speezy
//
//  Created by Matt Beaney on 23/12/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import UIKit
import FirebaseAuth

protocol ProfileCreationViewControllerDelegate: AnyObject {
    func profileCreationViewControllerDidCompleteSignup(_ viewController: ProfileCreationViewController)
    func profileCreationViewControllerDidGoBack(_ viewController: ProfileCreationViewController)
}

class ProfileCreationViewController: UIViewController {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var profileImg: UIImageView!
    @IBOutlet weak var attachBtn: SpeezyButton!
    
    @IBOutlet weak var nameTxtField: UITextField!
    @IBOutlet weak var aboutYouPlaceholder: UILabel!
    @IBOutlet weak var aboutYouTxtField: UITextView!
    
    @IBOutlet weak var completeSignupBtn: UIButton!
    @IBOutlet weak var completeSignupBtnContainer: UIView!
    @IBOutlet weak var loadingSpinner: UIActivityIndicatorView!
    
    weak var delegate: ProfileCreationViewControllerDelegate?
    var viewModel: FirebaseSignupViewModel!
    private var insetManager: KeyboardInsetManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTextFields()
        configureTextView()
        completeSignupBtnContainer.addShadow()
        configureInsetManager()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        profileImg.layer.cornerRadius = profileImg.frame.width / 2.0
        attachBtn.layer.cornerRadius = attachBtn.frame.width / 2.0
        completeSignupBtnContainer.layer.cornerRadius = completeSignupBtnContainer.frame.height / 2.0
        completeSignupBtnContainer.clipsToBounds = true
    }
    
    override func willMove(toParent parent: UIViewController?) {
        super.willMove(toParent: parent)
        
        if parent == nil {
            insetManager.stopListening()
        }
    }
    
    @IBAction func attachProfileImage(_ sender: Any) {
        showAttachmentAlert()
    }
    
    @IBAction func completeSignup(_ sender: Any) {
        startLoading()
        viewModel.createProfile {
            DispatchQueue.main.async {
                self.stopLoading()
                self.delegate?.profileCreationViewControllerDidCompleteSignup(self)
            }
        }
    }
    
    @IBAction func goBack(_ sender: Any) {
        delegate?.profileCreationViewControllerDidGoBack(self)
    }
    
    private func startLoading() {
        completeSignupBtn.isHidden = true
        loadingSpinner.isHidden = false
        loadingSpinner.startAnimating()
    }
    
    private func stopLoading() {
        completeSignupBtn.isHidden = false
        loadingSpinner.isHidden = true
        loadingSpinner.stopAnimating()
    }
    
    private func configureTextFields() {
        nameTxtField.makePlaceholderGrey()
        nameTxtField.delegate = self
        nameTxtField.text = viewModel.profile.name
        
        configureAboutYouPlaceholder()
    }
    
    private func configureAboutYouPlaceholder() {
        if viewModel.profile.aboutYou.isEmpty {
            aboutYouPlaceholder.isHidden = false
        } else {
            aboutYouPlaceholder.isHidden = true
        }
    }
    
    private func configureInsetManager() {
        self.insetManager = KeyboardInsetManager(
            view: view,
            scrollView: scrollView
        )
        
        self.insetManager.startListening()
    }
}

extension ProfileCreationViewController: UITextFieldDelegate {
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
        
        if textField == nameTxtField {
            viewModel.profile.name = updatedText
        }
        
        return true
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
            viewModel.profile.aboutYou = updatedText
            configureAboutYouPlaceholder()
        }
        
        return true
    }
}

extension ProfileCreationViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    private func configureProfileImage() {
        attachBtn.startLoading(color: .lightGray)
        attachBtn.imageView?.contentMode = .scaleAspectFill
        
        let imageApplication: (UIImage?) -> Void = { image in
            self.attachBtn.stopLoading()
            self.profileImg.layer.cornerRadius = 10.0
            self.attachBtn.setImage(UIImage(named: "camera-button"), for: .normal)
            self.profileImg.image = image
        }
        
        // TODO: Fetch image attachment and apply it somehow.
    }
    
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
            attachBtn.startLoading(color: .lightGray)
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
            
            
            // TODO: Set downloaded image.
            self.configureProfileImage()
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        attachBtn.stopLoading()
        picker.dismiss(animated: true, completion: nil)
    }
}
