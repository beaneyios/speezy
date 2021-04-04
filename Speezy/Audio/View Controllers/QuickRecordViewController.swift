//
//  QuickRecordViewController.swift
//  Speezy
//
//  Created by Matt Beaney on 28/11/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import UIKit

protocol QuickRecordViewControllerDelegate: AnyObject {
    func quickRecordViewController(_ viewController: QuickRecordViewController, didFinishRecordingItem item: AudioItem)
    func quickRecordViewControllerDidCancel(_ viewController: QuickRecordViewController)
}

class QuickRecordViewController: UIViewController {
    @IBOutlet weak var mainWaveContainer: UIView!
    @IBOutlet weak var btnRecord: SpeezyButton!
    @IBOutlet weak var lblTime: UILabel!
    @IBOutlet weak var recordingContainer: UIView!
    @IBOutlet weak var recordingControlsContainer: UIView!
    @IBOutlet weak var recordingContainerBackground: UIImageView!
    @IBOutlet weak var recordingContainerHeight: NSLayoutConstraint!
    @IBOutlet weak var backgroundView: UIView!
    
    var startHeight: CGFloat = 160.0
    
    weak var delegate: QuickRecordViewControllerDelegate?
    var audioManager: AudioManager!
    
    private var mainWave: PlaybackWaveView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        audioManager.addRecorderObserver(self)
        configureDialogue()
        
        btnRecord.disable()
        btnRecord.startLoading()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateInDialogue()
    }
    
    @IBAction func stopRecording(_ sender: Any) {
        audioManager.stopRecording()
    }
    
    private func animateInDialogue() {
        recordingControlsContainer.alpha = 0.0
        recordingContainerHeight.constant = 400

        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        } completion: { _ in
            UIView.animate(withDuration: 0.3) {
                self.recordingControlsContainer.alpha = 1.0
            } completion: { _ in
                self.configureMainSoundWave()
            }
        }
    }
    
    private func animateOutDialogue(completion: @escaping () -> Void) {
        UIView.animate(withDuration: 0.2) {
            self.recordingControlsContainer.alpha = 0.0
        } completion: { _ in
            self.recordingContainerHeight.constant = self.startHeight
            UIView.animate(withDuration: 0.2) {
                self.view.layoutIfNeeded()
            } completion: { _ in
                UIView.animate(withDuration: 0.2) {
                    self.view.alpha = 0.0
                } completion: { _ in
                    completion()
                }
            }
        }
    }
    
    private func configureDialogue() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissRecording))
        backgroundView.addGestureRecognizer(tapGesture)
        backgroundView.isUserInteractionEnabled = true
        
        let panTop = UIPanGestureRecognizer(target: self, action: #selector(topPan(sender:)))
        panTop.cancelsTouchesInView = false
        
        recordingContainer.layer.cornerRadius = 20.0
        recordingContainer.clipsToBounds = true
        recordingContainer.layer.cornerRadius = 20.0
        recordingContainer.layer.maskedCorners = [
            .layerMinXMinYCorner, .layerMaxXMinYCorner
        ]
        
        recordingContainer.addGestureRecognizer(panTop)
        recordingContainer.isUserInteractionEnabled = true
        
        recordingContainerHeight.constant = startHeight
    }
    
    private func configureMainSoundWave() {
        mainWave?.removeFromSuperview()
        mainWave = nil
        
        let soundWaveView = PlaybackWaveView.instanceFromNib()
        mainWaveContainer.addSubview(soundWaveView)
        
        soundWaveView.snp.makeConstraints { (maker) in
            maker.edges.equalTo(self.mainWaveContainer)
        }
        
        soundWaveView.configure(manager: audioManager, scrollable: false) {
            self.audioManager.startRecording()
        }
        
        mainWave = soundWaveView
    }
}

extension QuickRecordViewController: AudioRecorderObserver {
    func recordingBegan() {
    }
    
    func recordedBar(withPower decibel: Float, stepDuration: TimeInterval, totalDuration: TimeInterval) {
        btnRecord.stopLoading()
        if totalDuration > 3.0 {
            btnRecord.enable()
        }
        
        lblTime.text = TimeFormatter.formatTime(time: totalDuration)
    }
    
    func recordingProcessing() {
        btnRecord.startLoading()
    }
    
    func recordingStopped(maxLimitedReached: Bool) {
        animateOutDialogue {
            self.delegate?.quickRecordViewController(self, didFinishRecordingItem: self.audioManager.item)
        }
    }
}

extension QuickRecordViewController {
    @objc func dismissRecording() {
        audioManager.cancelRecording()
        recordingContainer.isUserInteractionEnabled = false
        
        animateOutDialogue {
            self.delegate?.quickRecordViewControllerDidCancel(self)
        }
    }
    
    @objc func topPan(sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: view)
        
        switch sender.state {
        case .changed:
            recordingContainerHeight.constant = 400.0 - translation.y
            view.layoutIfNeeded()
            
            if recordingContainerHeight.constant < 230.0 {
                recordingContainerHeight.constant = 230.0
            }
        case .ended:
            if translation.y > 125.0 {
                dismissRecording()
            } else {
                recordingContainerHeight.constant = 400.0
                
                UIView.animate(withDuration: 0.3, animations: {
                    self.view.layoutIfNeeded()
                })
            }
        default:
            break
        }
        
        view.layoutIfNeeded()
    }
}
