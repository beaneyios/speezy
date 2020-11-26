//
//  CutViewController.swift
//  Speezy
//
//  Created by Matt Beaney on 19/11/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import UIKit

protocol CutViewControllerDelegate: AnyObject {
    func cutViewControllerDidTapClose(_ viewController: CutViewController)
}

class CutViewController: UIViewController {
    @IBOutlet weak var lblTime: UILabel!
    @IBOutlet weak var playbackWaveContainer: UIView!
    
    @IBOutlet weak var btnStart: UIButton!
    @IBOutlet weak var btnEnd: UIButton!
    @IBOutlet weak var btnPlay: UIButton!
    
    weak var delegate: CutViewControllerDelegate?
    
    var manager: AudioManager!
    var waveView: PlaybackWaveView!
    
    enum State {
        case none
        case start
        case end
    }
    
    private var state: State = .start
    private var startPercentage: Float = 0.0
    private var endPercentage: Float = 1.0
    
    private var startTime: TimeInterval {
        manager.duration * Double(startPercentage)
    }

    private var endTime: TimeInterval {
        manager.duration * Double(endPercentage)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configurePlaybackView()
        configureButtons()
        
        manager.addPlaybackObserver(self)
    }
    
    @IBAction func closeTapped(_ sender: Any) {
        delegate?.cutViewControllerDidTapClose(self)
    }
    
    @IBAction func startTapped(_ sender: Any) {
        if state == .start {
            state = .none
        } else {
            state = .start
            manager.seek(to: startPercentage)
            waveView.seekToLeftCropHandle()
        }
        
        configureButtons()
    }
    
    @IBAction func endTapped(_ sender: Any) {
        if state == .end {
            state = .none
        } else {
            state = .end
            manager.seek(to: endPercentage)
            waveView.seekToRightCropHandle()
        }
        
        configureButtons()
    }
    
    @IBAction func playTapped(_ sender: Any) {
        manager.togglePlayback()
    }
    
    private func configureButtons() {
        btnStart.configure()
        btnEnd.configure()
        
        switch state {
        case .none:
            btnStart.toggleOff()
            btnEnd.toggleOff()
        case .start:
            btnStart.toggleOn()
            btnEnd.toggleOff()
        case .end:
            btnStart.toggleOff()
            btnEnd.toggleOn()
        }
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
        lblTime.text = TimeFormatter.formatTime(time: time + startOffset)
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
                if floatPercentage <= startPercentage {
                    waveView.seek(to: Double(startPercentage))
                }
                
                if floatPercentage >= endPercentage {
                    waveView.seek(to: Double(endPercentage))
                }
            case .start:
                if floatPercentage + 0.015 >= endPercentage {
                    waveView.seek(to: Double(startPercentage))
                    return
                }
                
                startPercentage = floatPercentage
                waveView.leftCropHandle(movedToPercentage: percentage)
            case .end:
                if floatPercentage <= startPercentage + 0.015 {
                    waveView.seek(to: Double(endPercentage))
                    return
                }
                
                endPercentage = floatPercentage
                waveView.rightCropHandle(movedToPercentage: percentage)
            }
        }
    }
}

fileprivate extension UIButton {
    func configure() {
        layer.borderWidth = 1.0
        layer.borderColor = UIColor.white.cgColor
        layer.cornerRadius = 4.0
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
