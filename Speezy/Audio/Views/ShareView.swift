//
//  ShareView.swift
//  Speezy
//
//  Created by Matt Beaney on 22/08/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import UIKit

class ShareViewController: UIView, NibLoadable {
    @IBOutlet weak var collectionView: UICollectionView!
    
    let options: [ShareOption] = [
        ShareOption(title: "WhatsApp", image: UIImage(named: "whatsapp-share-icon")),
        ShareOption(title: "Email", image: UIImage(named: "email-share-icon")),
        ShareOption(title: "Messenger", image: UIImage(named: "messenger-share-icon"))
    ]
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        collectionView.register(ShareOptionCell.nib, forCellWithReuseIdentifier: "cell")
        collectionView.delegate = self
        collectionView.dataSource = self
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


