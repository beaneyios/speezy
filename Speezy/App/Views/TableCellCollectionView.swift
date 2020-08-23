//
//  TableCellCollectionView.swift
//  Speezy
//
//  Created by Matt Beaney on 22/08/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import UIKit

class TableCellCollectionView: UICollectionView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if let hitView = super.hitTest(point, with: event) {
            if hitView is TableCellCollectionView {
                return nil
            } else {
                return hitView
            }
        } else {
            return nil
        }
    }
}
