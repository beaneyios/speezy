//
//  HomeViewController.swift
//  Speezy
//
//  Created by Matt Beaney on 24/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import UIKit
import FirebaseAuth
import FBSDKLoginKit

protocol HomeViewControllerDelegate: AnyObject {
    func homeViewControllerDidSelectChats(_ viewController: HomeViewController)
    func homeViewControllerDidSelectAudio(_ viewController: HomeViewController)
    func homeViewControllerDidSelectContacts(_ viewController: HomeViewController)
    func homeViewControllerDidSelectSignOut(_ viewController: HomeViewController)
}

class HomeViewController: UIViewController {
    weak var delegate: HomeViewControllerDelegate?
    
    
    @IBAction func goToAudio(_ sender: Any) {
        delegate?.homeViewControllerDidSelectAudio(self)
    }
    
    @IBAction func goToChat(_ sender: Any) {
        delegate?.homeViewControllerDidSelectChats(self)
    }
    
    @IBAction func goToContacts(_ sender: Any) {
        delegate?.homeViewControllerDidSelectContacts(self)
    }
    
    @IBAction func logout(_ sender: Any) {
        LoginManager().logOut()
        try? Auth.auth().signOut()
        delegate?.homeViewControllerDidSelectSignOut(self)
    }
}
