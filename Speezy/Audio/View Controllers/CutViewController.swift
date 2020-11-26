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
    
    @IBOutlet weak var btnStart: UIButton!
    @IBOutlet weak var btnEnd: UIButton!
    @IBOutlet weak var btnPlay: UIButton!
    
    var manager: AudioManager!
    
    var waveView: PlaybackWaveView!
    
    enum State {
        case none
        case start
        case end
    }
    
    private var state: State = .none
    private var startPercentage: Float = 0.0
    private var endPercentage: Float = 1.0
    
    private var startTime: TimeInterval {

        let thingy = manager.duration * Double(startPercentage)
        print(thingy)
        return thingy
    }

    private var endTime: TimeInterval {
        manager.duration * Double(endPercentage)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configurePlaybackView()
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
            
            manager.seek(to: startPercentage)
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
            
            manager.seek(to: endPercentage)
            waveView.seekToRightCropHandle()
        }
    }
    
    @IBAction func playTapped(_ sender: Any) {
        manager.togglePlayback()
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
        
        playbackView.configure(manager: manager) {
            self.manager.startCutting()
        }
        playbackView.delegate = self
        waveView = playbackView
    }
}

extension CutViewController: AudioPlayerObserver {
    func playBackBegan(on item: AudioItem) {
        btnPlay.setImage(
            UIImage(named: "pause-button"), for: .normal
        )
    }

    func playbackPaused(on item: AudioItem) {
        btnPlay.setImage(
            UIImage(named: "play-button"), for: .normal
        )
    }

    func playbackStopped(on item: AudioItem) {
        btnPlay.setImage(
            UIImage(named: "play-button"), for: .normal
        )
    }

    func playbackProgressed(
        withTime time: TimeInterval,
        seekActive: Bool,
        onItem item: AudioItem,
        startOffset: TimeInterval
    ) {
        lblTime.text = TimeFormatter.formatTime(time: time)
    }
}

extension CutViewController: PlaybackWaveViewDelegate {
    func playbackViewDidFinishScrolling(_ playbackView: PlaybackWaveView) {
        switch state {
        case .start, .end:
            manager.cut(
                from: startTime,
                to: endTime
            )
        default:
            break
        }
    }
    
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
                startPercentage = floatPercentage
                waveView.leftCropHandle(movedToPercentage: percentage)
            case .end:
                endPercentage = floatPercentage
                waveView.rightCropHandle(movedToPercentage: percentage)
            }
        }
    }
}

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
