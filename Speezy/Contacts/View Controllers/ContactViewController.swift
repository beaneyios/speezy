//
//  ContactViewController.swift
//  Speezy
//
//  Created by Matt Beaney on 02/05/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import UIKit
import JGProgressHUD

protocol ContactViewControllerDelegate: AnyObject {
    func contactViewControllerDidTapBack(_ viewController: ContactViewController)
    func contactViewController(
        _ viewController: ContactViewController,
        didLoadExistingChat chat: Chat
    )
    func contactViewController(
        _ viewController: ContactViewController,
        didStartNewChatWithContact contact: Contact
    )
}

class ContactViewController: UIViewController {
    @IBOutlet weak var profileViewContainer: UIView!
    @IBOutlet weak var startChatContainer: UIView!
    @IBOutlet weak var deleteContainer: UIView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var titleLabel: UILabel!
    
    private var startChatButton: GradientButton!
    private var deleteButton: GradientButton!
    
    private var profileViewController: ProfileViewController!
    
    weak var delegate: ContactViewControllerDelegate?
    var viewModel: ContactViewModel!
    
    private var hud: JGProgressHUD?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        spinner.startAnimating()
        deleteContainer.alpha = 0.0
        startChatContainer.alpha = 0.0
        
        viewModel.didChange = { change in
            DispatchQueue.main.async {
                switch change {
                case .profileLoaded:
                    self.configureProfileViewController()
                    self.configureStartChatButton()
                    self.configureDeleteButton()
                    self.animateButtons()
                    self.spinner.stopAnimating()
                    self.spinner.isHidden = true
                    
                    if let profileName = self.viewModel.profile?.name {
                        self.titleLabel.text = "\(profileName) profile"
                    } else {
                        self.titleLabel.text = "Profile"
                    }
                case let .loadExistingChat(chat):
                    self.delegate?.contactViewController(
                        self,
                        didLoadExistingChat: chat
                    )
                case let .startNewChat(contact):
                    self.delegate?.contactViewController(
                        self,
                        didStartNewChatWithContact: contact
                    )
                case .contactDeleted:
                    self.delegate?.contactViewControllerDidTapBack(self)
                case let .loading(isLoading):
                    if isLoading {
                        let hud = JGProgressHUD()
                        hud.textLabel.text = "Loading..."
                        hud.show(in: self.view)
                        self.hud = hud
                    } else {
                        self.hud?.dismiss()
                        self.hud = nil
                    }
                }
            }
        }
        
        viewModel.loadData()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        startChatContainer.layer.cornerRadius = startChatContainer.frame.height / 2.0
        startChatContainer.clipsToBounds = true
        
        deleteContainer.layer.cornerRadius = deleteContainer.frame.height / 2.0
        deleteContainer.clipsToBounds = true
        
        startChatContainer.clipsToBounds = true
        startChatContainer.layer.borderWidth = 1.0
        startChatContainer.layer.borderColor = UIColor.speezyPurple.cgColor
    }
    
    @IBAction func goBack(_ sender: Any) {
        delegate?.contactViewControllerDidTapBack(self)
    }
    
    private func configureDeleteButton() {
        let button = GradientButton.createFromNib()
        deleteContainer.addSubview(button)
        button.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
        
        button.configure(title: "Delete contact") {
            self.deleteContact()
        }
        
        self.deleteButton = button
    }
    
    private func deleteContact() {
        let alert = UIAlertController(
            title: "Confirm deletion",
            message: "Are you sure you want to delete this contact? You will also be removed from their contact list",
            preferredStyle: .alert
        )
        
        let delete = UIAlertAction(title: "Delete contact", style: .destructive) { _ in
            self.viewModel.deleteContact()
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alert.addAction(delete)
        alert.addAction(cancel)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    private func configureStartChatButton() {
        let button = GradientButton.createFromNib()
        startChatContainer.addSubview(button)
        button.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
        
        button.configure(title: "Start chat", color: .purple) {
            self.viewModel.loadChatWithContact()
        }
        
        self.startChatButton = button
    }
    
    private func animateButtons() {
        view.setNeedsLayout()
        view.layoutIfNeeded()
        
        [startChatContainer, deleteContainer].enumerated().forEach {
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
        
        profileViewController.canEditProfile = false
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

