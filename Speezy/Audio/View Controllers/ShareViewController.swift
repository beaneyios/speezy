//
//  ShareView.swift
//  Speezy
//
//  Created by Matt Beaney on 22/08/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import UIKit

protocol ShareViewControllerDelegate: AnyObject {
    func shareViewControllerShouldPop(_ shareViewController: ShareViewController)
}

class ShareViewController: UIViewController {
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var shareHeight: NSLayoutConstraint!
    @IBOutlet weak var shareContainer: UIView!
    
    weak var delegate: ShareViewControllerDelegate?
    
    let options: [ShareOption] = [
        ShareOption(title: "WhatsApp", image: UIImage(named: "whatsapp-share-icon")),
        ShareOption(title: "Email", image: UIImage(named: "email-share-icon")),
        ShareOption(title: "Messenger", image: UIImage(named: "messenger-share-icon"))
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.register(ShareOptionCell.nib, forCellWithReuseIdentifier: "cell")
        collectionView.delegate = self
        collectionView.dataSource = self
        
        let panTop = UIPanGestureRecognizer(target: self, action: #selector(topPan(sender:)))
        panTop.cancelsTouchesInView = false
        shareContainer.addGestureRecognizer(panTop)
        shareContainer.isUserInteractionEnabled = true
        
        shareHeight.constant = 0.0
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        shareHeight.constant = 250.0
        
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    @objc func dismissShare() {
        shareHeight.constant = 0.0
        
        UIView.animate(withDuration: 0.3, animations: {
            self.view.layoutIfNeeded()
        }) { (finished) in
            self.delegate?.shareViewControllerShouldPop(self)
        }
    }
    
    @objc func topPan(sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: view)
        
        shareHeight.constant = 250.0 - translation.y
        view.layoutIfNeeded()
        
        if translation.y > 125.0 {
            dismissShare()
        }
    }
}

extension ShareViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        options.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! ShareOptionCell
        cell.configure(with: options[indexPath.row])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let length = collectionView.frame.height
        return CGSize(width: length, height: length)
    }
}


