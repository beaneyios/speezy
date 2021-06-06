//
//  CropViewController.swift
//  Speezy
//
//  Created by Matt Beaney on 27/11/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import UIKit

protocol CropViewControllerDelegate: AnyObject {
    func cropViewControllerDidFinishCrop(_ viewController: CropViewController)
    func cropViewControllerDidTapClose(_ viewController: CropViewController)
}

class CropViewController: UIViewController {
    enum State {
        case none
        case start
        case end
    }
    
    @IBOutlet weak var btnClose: UIButton!
    
    @IBOutlet weak var lblTime: UILabel!
    @IBOutlet weak var btnPlay: UIButton!
    
    @IBOutlet weak var playbackWaveContainer: UIView!
    @IBOutlet weak var cropHandleContainer: UIView!
    
    @IBOutlet weak var btnCrop: UIButton!
    
    weak var delegate: CropViewControllerDelegate?
    var manager: AudioManager!
    
    private var waveView: PlaybackWaveView!
    private var cropView: CropView?
    
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
        configureWaveView()
        configureCropHandleView()
        manager.addPlaybackObserver(self)
        manager.addCropperObserver(self)
    }
    
    @IBAction func togglePlayback(_ sender: Any) {
        manager.togglePlayback()
    }
    
    @IBAction func closeTapped(_ sender: Any) {
        delegate?.cropViewControllerDidTapClose(self)
    }
    
    @IBAction func cropTapped(_ sender: Any) {
        manager.applyCrop()
    }
    
    private func configureWaveView() {
        let playbackView = PlaybackWaveView.instanceFromNib()
        playbackWaveContainer.addSubview(playbackView)
        
        playbackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        playbackView.configure(manager: manager) {
            self.manager.startCropping()
        }
        
        playbackView.delegate = self
        waveView = playbackView
    }
    
    private func configureCropHandleView() {
        let cropView = CropView.instanceFromNib()
        cropView.alpha = 0.0
        cropHandleContainer.addSubview(cropView)
        
        cropView.snp.makeConstraints { (maker) in
            maker.edges.equalTo(cropHandleContainer)
        }
        
        self.cropView = cropView
        cropView.configure(manager: manager)
        
        UIView.animate(withDuration: 0.3) {
            cropView.alpha = 1.0
        }
    }
}

extension CropViewController: AudioPlayerObserver {
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
        switch state {
        case .start:
            lblTime.text = TimeFormatter.formatTime(time: startTime)
        case .end:
            lblTime.text = TimeFormatter.formatTime(time: endTime)
        case .none:
            lblTime.text = TimeFormatter.formatTime(time: time + startOffset)
        }
    }
}

extension CropViewController: AudioCropperObserver {
    func croppingStarted(onItem item: AudioItem) {}
    
    func cropRangeAdjusted(onItem item: AudioItem) {
        state = .none
    }
    
    func croppingFinished(onItem item: AudioItem) {
        delegate?.cropViewControllerDidFinishCrop(self)
    }
    
    func leftCropHandle(movedToPercentage percentage: CGFloat) {
        let floatPercentage = percentage > 1.0 ? 1.0 : Float(percentage)
        manager.seek(to: floatPercentage)
        state = .start
        startPercentage = Float(percentage)
        waveView.seek(to: Double(percentage))
        waveView.leftCropHandle(movedToPercentage: percentage)
    }
    
    func rightCropHandle(movedToPercentage percentage: CGFloat) {
        let floatPercentage = percentage > 1.0 ? 1.0 : Float(percentage)
        manager.seek(to: floatPercentage)
        state = .end
        endPercentage = Float(percentage)
        waveView.seek(to: Double(percentage))
        waveView.rightCropHandle(movedToPercentage: percentage)
    }
    
    func croppingCancelled() {
        delegate?.cropViewControllerDidTapClose(self)
    }
}

extension CropViewController: PlaybackWaveViewDelegate {
    func playbackView(
        _ playbackView: PlaybackWaveView,
        didFinishScrollingOnPosition percentage: CGFloat
    ) {
        
    }
    
    func playbackView(
        _ playbackView: PlaybackWaveView,
        didScrollToPosition percentage: CGFloat,
        userInitiated: Bool
    ) {
        if userInitiated {
            let floatPercentage = percentage > 1.0 ? 1.0 : Float(percentage)
            manager.seek(to: floatPercentage)
            
            switch state {
            case .none:
                if floatPercentage <= startPercentage {
                    waveView.seek(to: Double(startPercentage))
                    return
                }
                
                if floatPercentage >= endPercentage {
                    waveView.seek(to: Double(endPercentage))
                    return
                }
            default:
                break
            }
        }
    }
}
