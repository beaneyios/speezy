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

class TagsView: UIView, NibLoadable {
    
    @IBOutlet weak var collectionView: UICollectionView!
    private var tags = [Tag]()
    
    private var foreColor: UIColor!
    private var backColor: UIColor!
    
    func configure(with tags: [Tag], foreColor: UIColor, backColor: UIColor, scrollDirection: UICollectionView.ScrollDirection, showAddTag: Bool) {
        self.foreColor = foreColor
        self.backColor = backColor
        self.tags = tags
        
        if showAddTag {
            self.tags.append(
                Tag(
                    id: "add_tag",
                    title: "Add Tag +"
                )
            )
        }
        
        addSubview(collectionView)
        collectionView.register(TagCell.nib, forCellWithReuseIdentifier: "cell")
        
        switch scrollDirection {
        case .horizontal:
            let layout = UICollectionViewFlowLayout()
            layout.scrollDirection = scrollDirection
            collectionView.collectionViewLayout = layout
        default:
            let layout = LeftAlignedCollectionViewFlowLayout()
            layout.scrollDirection = .vertical
            collectionView.collectionViewLayout = layout
        }
        
        collectionView.dataSource = self
        collectionView.delegate = self
    }
}

extension TagsView: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        tags.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! TagCell
        let tag = tags[indexPath.row]
        
        let backgroundColor: UIColor = {
            if tag.id == "add_tag" {
                return .white
            } else {
                return backColor
            }
        }()
        
        let foregroundColor: UIColor = {
            if tag.id == "add_tag" {
                return .black
            } else {
                return foreColor
            }
        }()
        
        cell.configure(
            with: tag,
            foregroundColor: foregroundColor,
            backgroundColor: backgroundColor
        )
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let tag = tags[indexPath.row]
        let cell = TagCell.createFromNib()
        
        cell.frame.size.height = 16.0
        cell.configure(with: tag, foregroundColor: foreColor, backgroundColor: backColor)
        
        let size = cell.systemLayoutSizeFitting(
            CGSize(
                width: UIView.layoutFittingCompressedSize.width,
                height: 16.0
            )
        )
        
        return size
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let tag = tags[indexPath.row]
        
        if tag.id == "add_tag" {
            print("Add tag here")
        }
    }
}

class LeftAlignedCollectionViewFlowLayout: UICollectionViewFlowLayout {

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let attributes = super.layoutAttributesForElements(in: rect)

        var leftMargin = sectionInset.left
        var maxY: CGFloat = -1.0
        attributes?.forEach { layoutAttribute in
            if layoutAttribute.frame.origin.y >= maxY {
                leftMargin = sectionInset.left
            }

            layoutAttribute.frame.origin.x = leftMargin

            leftMargin += layoutAttribute.frame.width + minimumInteritemSpacing
            maxY = max(layoutAttribute.frame.maxY , maxY)
        }

        return attributes
    }
}
