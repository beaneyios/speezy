//
//  ProfileEditViewController.swift
//  Speezy
//
//  Created by Matt Beaney on 16/02/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import UIKit

protocol ProfileEditViewControllerDelegate: AnyObject {
    func profileEditViewControllerDidLoadContacts(_ viewController: ProfileEditViewController)
}

class ProfileEditViewController: UIViewController {
    @IBOutlet weak var profileViewContainer: UIView!
    @IBOutlet weak var updateButtonContainer: UIView!
    @IBOutlet weak var contactsButtonContainer: UIView!
    @IBOutlet weak var shareContainer: UIView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    private var updateButton: GradientButton!
    private var contactsButton: GradientButton!
    private var shareButton: GradientButton!
    
    private var profileViewController: ProfileViewController!
    
    weak var delegate: ProfileEditViewControllerDelegate?
    var viewModel: ProfileEditViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        spinner.startAnimating()
        shareContainer.alpha = 0.0
        contactsButtonContainer.alpha = 0.0
        updateButtonContainer.alpha = 0.0
        
        viewModel.didChange = { change in
            DispatchQueue.main.async {
                switch change {
                case .profileLoaded:
                    self.configureProfileViewController()
                    self.configureSignupButton()
                    self.configureContactsButton()
                    self.configureShareButton()
                    self.animateButtons()
                    self.spinner.stopAnimating()
                    self.spinner.isHidden = true
                case .saved:
                    self.updateButton.stopLoading()
                }
            }
        }
        
        viewModel.loadData()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        contactsButtonContainer.layer.cornerRadius = contactsButtonContainer.frame.height / 2.0
        contactsButtonContainer.clipsToBounds = true
        
        updateButtonContainer.layer.cornerRadius = updateButtonContainer.frame.height / 2.0
        updateButtonContainer.clipsToBounds = true
        
        shareContainer.layer.cornerRadius = updateButtonContainer.frame.height / 2.0
        shareContainer.clipsToBounds = true
        shareContainer.layer.borderWidth = 1.0
        shareContainer.layer.borderColor = UIColor.speezyPurple.cgColor
    }
    
    private func configureShareButton() {
        let button = GradientButton.createFromNib()
        shareContainer.addSubview(button)
        button.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
        
        button.configure(
            title: "Invite a friend",
            titleColor: .speezyPurple,
            color: .clear,
            iconImage: UIImage(named: "share-button")
        ) {
            guard
                let contactId = self.viewModel.contact?.id,
                let dynamicLinkDomain = Bundle.main.infoDictionary?["DYNAMIC_LINK_DOMAIN"] as? String
            else {
                return
            }
            
            let linkParam = "https%3A%2F%2Fsospeezy.com%2Fadd-friend%3Fcontact_id%3D\(contactId)"
                
            let items: [Any] = [
                "Add me on Speezy",
                URL(
                    string: "https://\(dynamicLinkDomain)?link=\(linkParam)&ibi=com.suggestv.speezy-app&isi=1557121831"
                )!
            ]
            let ac = UIActivityViewController(
                activityItems: items,
                applicationActivities: nil
            )
            self.present(ac, animated: true)
        }
        
        self.shareButton = button
    }
    
    private func configureContactsButton() {
        let button = GradientButton.createFromNib()
        contactsButtonContainer.addSubview(button)
        button.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
        
        button.configure(title: "Contacts", color: .purple) {
            self.delegate?.profileEditViewControllerDidLoadContacts(self)
        }
        
        self.contactsButton = button
    }
    
    private func configureSignupButton() {
        let button = GradientButton.createFromNib()
        updateButtonContainer.addSubview(button)
        button.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
        
        button.configure(title: "Update your profile") {
            self.viewModel.updateProfile()
            button.startLoading()
        }
        
        self.updateButton = button
    }
    
    private func animateButtons() {
        view.setNeedsLayout()
        view.layoutIfNeeded()
        
        [shareContainer, contactsButtonContainer, updateButtonContainer].enumerated().forEach {
            guard let element = $0.element else {
                return
            }
            
            self.animateButton(button: element, offset: $0.offset)
        }
    }
    
    private func animateButton(button: UIView, offset: Int) {
        button.transform = button.transform.translatedBy(x: 0.0, y: 20.0)
        UIView.animate(withDuration: 0.6, delay: Double(offset) / 10.0, options: .curveEaseInOut) {
            button.alpha = 1.0
            button.transform = .identity
            self.view.layoutIfNeeded()
        } completion: { _ in
            print(button.alpha)
        }
    }
    
    private func configureProfileViewController() {
        let storyboard = UIStoryboard(name: "Profile", bundle: .main)
        
        guard let profileViewController = storyboard.instantiateViewController(identifier: "ProfileViewController") as? ProfileViewController else {
            return
        }
        
        profileViewController.canEditUsername = false
        profileViewController.viewModel = self.viewModel
        profileViewController.willMove(toParent: self)
        addChild(profileViewController)
        
        profileViewContainer.addSubview(profileViewController.view)
        profileViewController.view.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        self.profileViewController = profileViewController
    }
}
