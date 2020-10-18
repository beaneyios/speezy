//
//  PreviewWavePresenting.swift
//  Speezy
//
//  Created by Matt Beaney on 18/10/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import UIKit

protocol PreviewWavePresenting: AnyObject {
    var playbackContainer: UIView! { get }
    var waveContainer: UIView! { get }
    var waveView: PlaybackView! { get set }
}

extension PreviewWavePresenting {
    func configurePreviewWave(audioManager: AudioManager) {
        let soundWaveView = PlaybackView.instanceFromNib()
        waveContainer.addSubview(soundWaveView)
        
        soundWaveView.snp.makeConstraints { (maker) in
            maker.edges.equalTo(self.waveContainer)
        }
        
        soundWaveView.configure(manager: audioManager)
        waveView = soundWaveView
        
        playbackContainer.layer.cornerRadius = 10.0
    }
}
