//
//  CutViewController.swift
//  Speezy
//
//  Created by Matt Beaney on 19/11/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import UIKit

class CutViewController: UIViewController {
    @IBOutlet weak var lblTime: UILabel!
    @IBOutlet weak var playbackWaveContainer: UIView!
    
    var manager: AudioManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configurePlaybackView()
    }
    
    private func configurePlaybackView() {
        let playbackView = PlaybackWaveView.instanceFromNib()
        playbackWaveContainer.addSubview(playbackView)
        
        playbackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        playbackView.configure(manager: manager)
        playbackView.delegate = self
    }
}

extension CutViewController: PlaybackWaveViewDelegate {
    func playbackView(_ playbackView: PlaybackWaveView, didScrollToPosition percentage: CGFloat) {
        let floatPercentage = Float(percentage)
        manager.seek(to: floatPercentage)
    }
}
