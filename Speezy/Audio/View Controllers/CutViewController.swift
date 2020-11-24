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
    
    var waveView: PlaybackWaveView!
    
    enum State {
        case none
        case start
        case end
    }
    
    var state: State = .end
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configurePlaybackView()
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2.0) {
            if self.state == .end {
                self.waveView.seek(to: 1)
            }
            
            self.manager.startCutting()
        }
        
        
    }
    
    private func configurePlaybackView() {
        let playbackView = PlaybackWaveView.instanceFromNib()
        playbackWaveContainer.addSubview(playbackView)
        
        playbackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        playbackView.configure(manager: manager)
        playbackView.delegate = self
        waveView = playbackView
    }
}

extension CutViewController: PlaybackWaveViewDelegate {
    func playbackView(
        _ playbackView: PlaybackWaveView,
        didScrollToPosition percentage: CGFloat,
        userInitiated: Bool
    ) {
        if userInitiated {
            print(percentage)
            let floatPercentage = Float(percentage)
            manager.seek(to: floatPercentage)
            
            switch state {
            case .none:
                break
            case .start:
                waveView.leftCropHandle(movedToPercentage: percentage)
            case .end:
                waveView.rightCropHandle(movedToPercentage: percentage)
            }
        }
    }
}
