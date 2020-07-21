//
//  TagView.swift
//  Speezy
//
//  Created by Matt Beaney on 21/07/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

class TagsView: UIView {
    private var collectionView: UICollectionView!
    private var tags = [Tag]()
    
    override func awakeFromNib() {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        addSubview(collectionView)
        
        collectionView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
        
        self.collectionView = collectionView
    }
    
    func configure(with tags: [Tag]) {
        
    }
}

extension TagsView: UICollectionViewDataSource, UICollectionViewDelegate {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        tags.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return UICollectionViewCell()
    }
}
