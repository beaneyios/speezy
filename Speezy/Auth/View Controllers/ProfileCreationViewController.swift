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
    func profileCreationViewControllerDidCompleteSignup(
        _ viewController: ProfileCreationViewController,
        withUser user: User
    )
    func profileCreationViewControllerDidGoBack(
        _ viewController: ProfileCreationViewController
    )
}

class ProfileCreationViewController: UIViewController {
    
    @IBOutlet weak var completeSignupBtnContainer: UIView!
    @IBOutlet weak var profileViewContainer: UIView!
    @IBOutlet weak var bottomButtonConstraint: NSLayoutConstraint!
    
    private var completeSignupBtn: GradientButton?
    private var profileViewController: ProfileViewController!
    
    weak var delegate: ProfileCreationViewControllerDelegate?
    var viewModel: FirebaseSignupViewModel!
    
    lazy var insetManager = KeyboardConstraintManager(
        view: view,
        constraint: bottomButtonConstraint,
        defaultConstant: 16.0
    )
    
    override func viewDidLoad() {
        super.viewDidLoad()
        completeSignupBtnContainer.addShadow()
        configureSignupButton()
        configureProfileViewController()
        
        insetManager.startListening()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        completeSignupBtnContainer.layer.cornerRadius = completeSignupBtnContainer.frame.height / 2.0
        completeSignupBtnContainer.clipsToBounds = true
    }
    
    @IBAction func goBack(_ sender: Any) {
        delegate?.profileCreationViewControllerDidGoBack(self)
    }
    
    @IBAction func completeSignup(_ sender: Any) {
        completeSignup()
    }
    
    func completeSignup() {
        profileViewController.clearHighlightedFields()
        
        if let error = viewModel.profileValidationError() {
            profileViewController.highlightErroredFields(error: error)
            view.setNeedsLayout()
            view.layoutIfNeeded()
            return
        }
        
        completeSignupBtn?.startLoading()
        viewModel.createProfile { result in
            DispatchQueue.main.async {
                switch result {
                case let .failure(error):
                    self.profileViewController.highlightErroredFields(error: error)
                case let .success(user):
                    self.completeSignupBtn?.stopLoading()
                    self.delegate?.profileCreationViewControllerDidCompleteSignup(
                        self,
                        withUser: user
                    )
                }
                
                self.completeSignupBtn?.stopLoading()
            }
        }
    }
    
    private func configureProfileViewController() {
        let storyboard = UIStoryboard(name: "Profile", bundle: .main)
        
        guard let profileViewController = storyboard.instantiateViewController(identifier: "ProfileViewController") as? ProfileViewController else {
            return
        }
        
        profileViewController.listenForKeyboard = false
        profileViewController.viewModel = self.viewModel
        profileViewController.willMove(toParent: self)
        addChild(profileViewController)
        
        profileViewContainer.addSubview(profileViewController.view)
        profileViewController.view.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        self.profileViewController = profileViewController
    }
    
    private func configureSignupButton() {
        let button = GradientButton.createFromNib()
        completeSignupBtnContainer.addSubview(button)
        button.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
        
        button.configure(title: "FINISH") {
            self.completeSignup()
        }
        
        self.completeSignupBtn = button
    }
}
