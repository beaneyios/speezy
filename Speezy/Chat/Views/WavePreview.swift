//
//  WavePreview.swift
//  Speezy
//
//  Created by Matt Beaney on 11/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import UIKit

class WavePreview: UIView {
    private var wave: WaveView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    convenience init(
        levels: [Float],
        frame: CGRect,
        barColor: UIColor
    ) {
        self.init(frame: frame)
        
        let cropWave = AudioVisualizationView(
            frame: CGRect(
                x: 0,
                y: 0.0,
                width: frame.width,
                height: frame.height
            )
        )
        
        cropWave.gradientEndColor = barColor
        cropWave.gradientStartColor = .white
        cropWave.meteringLevelBarInterItem = 0.5
        cropWave.meteringLevelBarWidth = 0.5
        cropWave.audioVisualizationMode = .read
        cropWave.meteringLevels = levels
        
        cropWave.tintColor = barColor
        cropWave.backgroundColor = .clear
        cropWave.alpha = 0.0
                    
        addSubview(cropWave)
        self.wave = wave
        
        UIView.animate(withDuration: 0.4) {
            cropWave.alpha = 1.0
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
