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
    func shareViewController(_ shareViewController: ShareViewController, didSelectOption option: ShareOption)
}

class ShareViewController: UIViewController {
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var shareHeight: NSLayoutConstraint!
    @IBOutlet weak var shareContainer: UIView!
    @IBOutlet weak var backgroundView: UIView!
    
    @IBOutlet weak var shareViewBackground: UIView!
    
    weak var delegate: ShareViewControllerDelegate?
    
    var item: AudioItem!
    var attachment: UIImage?
    var completion: (() -> Void)?
    
    let options: [ShareOption] = [
        ShareOption(title: "Speezy", image: UIImage(named: "speezy-share-icon"), platform: .speezy),
        ShareOption(title: "Speezy Social", image: UIImage(named: "speezy-group-share-icon"), platform: .speezyPublic),
        ShareOption(title: "WhatsApp", image: UIImage(named: "whatsapp-share-icon"), platform: .whatsapp),
        ShareOption(title: "Messenger", image: UIImage(named: "messenger-share-icon"), platform: .messenger),
        ShareOption(title: "Email", image: UIImage(named: "email-share-icon"), platform: .email)
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.register(ShareOptionCell.nib, forCellWithReuseIdentifier: "cell")
        collectionView.delegate = self
        collectionView.dataSource = self
        
        shareContainer.tag = 10000001
        shareContainer.addShadow(
            offset: CGSize(width: 0, height: -5)
        )
        
        shareViewBackground.clipsToBounds = true
        shareViewBackground.layer.cornerRadius = 10.0
        shareViewBackground.layer.maskedCorners = [
            .layerMaxXMinYCorner,
            .layerMinXMinYCorner
        ]
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissShare))
        backgroundView.addGestureRecognizer(tapGesture)
        backgroundView.isUserInteractionEnabled = true
        
        let panTop = UIPanGestureRecognizer(target: self, action: #selector(topPan(sender:)))
        panTop.cancelsTouchesInView = false
        shareContainer.addGestureRecognizer(panTop)
        shareContainer.isUserInteractionEnabled = true
        
        shareHeight.constant = 0.0
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        shareHeight.constant = 250.0
        
        UIView.animate(withDuration: 0.3, animations: {
            self.view.layoutIfNeeded()
        })
    }
    
    @objc func dismissShare() {
        shareContainer.isUserInteractionEnabled = false
        shareHeight.constant = 0.0
        
        UIView.animate(withDuration: 0.3, animations: {
            self.view.layoutIfNeeded()
        }) { (finished) in
            self.delegate?.shareViewControllerShouldPop(self)
        }
    }
    
    @objc func topPan(sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: view)
        
        switch sender.state {
        case .changed:
            shareHeight.constant = 250.0 - translation.y
            view.layoutIfNeeded()
            
            if translation.y > 230.0 {
                self.delegate?.shareViewControllerShouldPop(self)
            }
        case .ended:
            if translation.y > 125.0 {
                dismissShare()
            } else {
                shareHeight.constant = 250.0
                
                UIView.animate(withDuration: 0.3, animations: {
                    self.view.layoutIfNeeded()
                })
            }
        default:
            break
        }
        
        view.layoutIfNeeded()
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
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        cell.alpha = 0.0
        cell.transform = CGAffineTransform(translationX: 0.0, y: 15.0)
        
        UIView.animate(withDuration: 0.4, delay: Double(indexPath.row) / 6.0, options: [], animations: {
            cell.alpha = 1.0
            cell.transform = CGAffineTransform.identity
        }) { (finished) in
            
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let option = options[indexPath.row]
        delegate?.shareViewController(self, didSelectOption: option)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let length = collectionView.frame.height
        return CGSize(width: length, height: length)
    }
}
