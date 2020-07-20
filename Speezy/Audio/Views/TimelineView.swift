//
//  TimelineView.swift
//  Speezy
//
//  Created by Matt Beaney on 20/07/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import Foundation
import UIKit

class TimelineView: UIView {
    
    private var previousLabel: UILabel?
    
    func createTimeLine(seconds: TimeInterval, width: CGFloat) {
        guard Int(seconds) > 0 else {
            return
        }
        
        let gap = width / CGFloat(seconds)
        
        (1...Int(seconds)).forEach {
            self.addSecond(second: $0, gap: gap)
        }
    }
    
    func addSecond(second: Int, gap: CGFloat) {
        let label = UILabel()
        label.alpha = 0.0
        label.font = UIFont.systemFont(ofSize: 12.0)
        label.text = "\(self.timeLabel(duration: TimeInterval(second)))"
        label.textColor = .white
        label.alpha = 0.0
        self.addSubview(label)
        
        if let previousLabel = previousLabel {
            label.snp.makeConstraints { (maker) in
                maker.centerX.equalTo(previousLabel.snp.centerX).offset(gap)
                maker.top.equalTo(self)
            }
        } else {
            label.snp.makeConstraints { (maker) in
                maker.centerX.equalTo(self.snp.leading).offset(gap)
                maker.top.equalTo(self)
            }
        }
        
        previousLabel = label
        
        let verticalLine = UIView()
        verticalLine.backgroundColor = .white
        verticalLine.alpha = 0.0
        self.addSubview(verticalLine)
        
        verticalLine.snp.makeConstraints { (maker) in
            maker.top.equalTo(self.snp.top).offset(24.0)
            maker.bottom.equalTo(self.snp.bottom)
            maker.width.equalTo(1.0)
            maker.leading.equalTo(label.snp.leading)
        }
        
        UIView.animate(withDuration: 0.3, delay: TimeInterval(second) / 10.0, options: [], animations: {
            label.alpha = 0.3
            verticalLine.alpha = 0.3
        }, completion: nil)
    }
    
    private func timeLabel(duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.allowedUnits = [ .minute, .second ]
        formatter.zeroFormattingBehavior = [ .pad ]
        return formatter.string(from: duration) ?? "\(duration)"
    }
}
