//
//  AudioVisualisationView2.swift
//  Speezy
//
//  Created by Matt Beaney on 02/09/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

class AudioVisualisationView2: UIView {
    private var trailingConstraint: Constraint?
    private var meteringViews: [UIView] = []
    
    func configure(with meteringLevels: [Float]) {
        meteringViews.forEach {
            $0.removeFromSuperview()
        }
        
        meteringViews = []
        
        meteringLevels.forEach {
            self.add(meteringLevel: $0)
        }
    }
    
    func add(meteringLevel: Float) {
        let meteringView = UIView()
        meteringView.backgroundColor = .red
        addSubview(meteringView)
        
        if let previousMeteringView = meteringViews.last {
            trailingConstraint?.deactivate()
            
            meteringView.snp.makeConstraints { (make) in
                make.centerY.equalToSuperview()
                make.left.equalTo(previousMeteringView.snp.right).offset(3.0)
                make.height.equalTo(self).multipliedBy(meteringLevel)
                make.width.equalTo(3.0)
                self.trailingConstraint = make.trailing.lessThanOrEqualToSuperview().constraint
            }
        } else {
            meteringView.snp.makeConstraints { (make) in
                make.centerY.equalToSuperview()
                make.leading.equalToSuperview()
                make.height.equalTo(self).multipliedBy(meteringLevel)
                make.width.equalTo(3.0)
                self.trailingConstraint = make.trailing.lessThanOrEqualToSuperview().constraint
            }
        }
        
        meteringViews.append(meteringView)
    }
}
