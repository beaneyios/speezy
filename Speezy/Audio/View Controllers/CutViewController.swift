//
//  CutViewController.swift
//  Speezy
//
//  Created by Matt Beaney on 19/11/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import UIKit

fileprivate extension UIButton {
    func configure() {
        backgroundColor = .clear
        layer.borderWidth = 1.0
        layer.borderColor = UIColor.white.cgColor
        layer.cornerRadius = 4.0
        setTitleColor(.white, for: .normal)
        
    }
    
    func toggleOn() {
        backgroundColor = .white
        setTitleColor(
            UIColor(named: "speezy-purple"),
            for: .normal
        )
    }
    
    func toggleOff() {
        backgroundColor = .clear
        setTitleColor(.white, for: .normal)
    }
}

class CutViewController: UIViewController {
    @IBOutlet weak var lblTime: UILabel!
    @IBOutlet weak var playbackWaveContainer: UIView!
    
    @IBOutlet weak var btnStart: UIButton!
    @IBOutlet weak var btnEnd: UIButton!
    var manager: AudioManager!
    
    var waveView: PlaybackWaveView!
    
    enum State {
        case none
        case start
        case end
    }
    
    var state: State = .none
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configurePlaybackView()
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2.0) {            
            self.manager.startCutting()
        }
        
        configureButtons()
    }
    
    @IBAction func startTapped(_ sender: Any) {
        if state == .start {
            state = .none
            btnStart.toggleOff()
        } else {
            state = .start
            btnEnd.toggleOff()
            btnStart.toggleOn()
            waveView.seekToLeftCropHandle()
        }
    }
    
    @IBAction func endTapped(_ sender: Any) {
        if state == .end {
            state = .none
            btnStart.toggleOff()
        } else {
            state = .end
            btnStart.toggleOff()
            btnEnd.toggleOn()
            waveView.seekToRightCropHandle()
        }
    }
    
    private func configureButtons() {
        btnStart.configure()
        btnEnd.configure()
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
