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
    
    private var updateButton: GradientButton!
    private var contactsButton: GradientButton!
    
    private var profileViewController: ProfileViewController!
    
    weak var delegate: ProfileEditViewControllerDelegate?
    var viewModel: ProfileEditViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel.didChange = { change in
            DispatchQueue.main.async {
                switch change {
                case .profileLoaded:
                    self.configureProfileViewController()
                    self.configureSignupButton()
                    self.configureContactsButton()
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
