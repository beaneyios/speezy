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

class WaveView: UIView {
    private var positionLeadingConstraint: Constraint?
    private var waveTrailingConstraint: Constraint?
    private var meteringViews: [UIView] = []
    
    private var position: UIView!
    
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
            waveTrailingConstraint?.deactivate()
            
            meteringView.snp.makeConstraints { (make) in
                make.centerY.equalToSuperview()
                make.left.equalTo(previousMeteringView.snp.right).offset(3.0)
                make.height.equalTo(self).multipliedBy(meteringLevel)
                make.width.equalTo(3.0)
                self.waveTrailingConstraint = make.trailing.lessThanOrEqualToSuperview().constraint
            }
        } else {
            meteringView.snp.makeConstraints { (make) in
                make.centerY.equalToSuperview()
                make.leading.equalToSuperview()
                make.height.equalTo(self).multipliedBy(meteringLevel)
                make.width.equalTo(3.0)
                self.waveTrailingConstraint = make.trailing.lessThanOrEqualToSuperview().constraint
            }
        }
        
        meteringViews.append(meteringView)
    }
    
    func advancePosition(percentage: Float) {
        if position == nil {
            position = UIView()
            position.backgroundColor = .white
            addSubview(position)
            position.snp.makeConstraints { (make) in
                make.width.equalTo(1.0)
                make.top.equalToSuperview()
                make.bottom.equalToSuperview()
                make.leading.equalToSuperview()
            }
        }
        
        position.snp.updateConstraints { (make) in
            make.leading.equalToSuperview().offset(self.frame.width * CGFloat(percentage))
        }
    }
}
