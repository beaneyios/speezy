//
//  ViewController.swift
//  Speezy
//
//  Created by Matt Beaney on 27/05/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import UIKit
import SwiftVideoGenerator
import AVKit
import SnapKit
import SoundWave

enum PlayerState {
    case fresh
    case playing
    case paused
}

class ViewController: UIViewController {
    @IBOutlet weak var btnCut: UIButton!
    @IBOutlet weak var btnPlayback: UIButton!
    @IBOutlet weak var btnRecord: UIButton!
    @IBOutlet weak var btnCrop: UIButton!
    
    @IBOutlet weak var lblTimer: UILabel!
    
    @IBOutlet weak var mainWaveContainer: UIView!
    
    @IBOutlet weak var trimContainer: UIView!
    @IBOutlet weak var trimContainerHeight: NSLayoutConstraint!
    
    private var mainWave: LargeSoundwaveView?
    private var trimWave: TrimmableSoundwaveView?
    
    var documentInteractionController: UIDocumentInteractionController?
    
    var audioManager: AudioManager!
            
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureAudioManager {
            DispatchQueue.main.async {
                self.configureMainSoundWave()
            }
        }
    
        hideTrimView(animated: false)
    }
    
    func configureAudioManager(completion: @escaping () -> Void) {
        let audioURL = Bundle.main.url(forResource: "test", withExtension: "m4a")!
        
        AudioEditor.convertOriginalToSpeezyFormat(url: audioURL) { (url) in
            self.audioManager = AudioManager(item: AudioItem(url: url))
            self.audioManager.addObserver(self)
            completion()
        }
    }
    
    func configureMainSoundWave() {        
        let soundWaveView = LargeSoundwaveView.instanceFromNib()
        mainWaveContainer.addSubview(soundWaveView)
        
        soundWaveView.snp.makeConstraints { (maker) in
            maker.edges.equalTo(self.mainWaveContainer)
        }
        
        soundWaveView.configure(manager: audioManager)
        mainWave = soundWaveView
    }
    
    @IBAction func toggleRecording(_ sender: Any) {
        btnRecord.setImage(UIImage(named: "stop-recording-button"), for: .normal)
    }
    
    @IBAction func toggleCrop(_ sender: Any) {
        toggleTrimView()
    }
    
    @IBAction func togglePlayback(_ sender: Any) {
        audioManager.togglePlayback()
    }
    
    @IBAction func toggleCut(_ sender: Any) {
        
    }
    
    func hideTrimView(animated: Bool) {
        trimContainerHeight.constant = 0.0
        trimContainer.alpha = 0.0
    }
    
    func toggleTrimView() {
        if let trimWave = self.trimWave {
            hideTrimWave(trimWave)
        } else {
            showTrimWave()
        }
    }
    
    func hideTrimWave(_ wave: TrimmableSoundwaveView) {
        btnCrop.setImage(UIImage(named: "crop-button"), for: .normal)
        
        UIView.animate(withDuration: 0.3, animations: {
            self.trimContainer.alpha = 0.0
        }) { (finished) in
            wave.removeFromSuperview()
            self.trimWave = nil            
            self.trimContainerHeight.constant = 0.0
        }
    }
    
    func showTrimWave() {
        btnCrop.setImage(UIImage(named: "crop-button-selected"), for: .normal)
        
        let trimWave = TrimmableSoundwaveView.instanceFromNib()
        trimWave.delegate = self
        trimContainer.addSubview(trimWave)
        
        trimWave.snp.makeConstraints { (maker) in
            maker.edges.equalTo(self.trimContainer)
        }
        
        trimContainer.layoutIfNeeded()
        trimContainerHeight.constant = 90.0
        UIView.animate(withDuration: 0.4, animations: {
            self.view.layoutIfNeeded()
            self.trimContainer.alpha = 1.0
        }) { (finished) in
            trimWave.configure(manager: self.audioManager)
        }
        
        self.trimWave = trimWave
    }
}

extension ViewController: TrimmableSoundWaveViewDelegate {
    func trimViewDidApplyTrim(_ view: TrimmableSoundwaveView) {
        let alert = UIAlertController(title: "Confirm crop", message: "Are you sure you want to crop?", preferredStyle: .alert)
        let crop = UIAlertAction(title: "Crop", style: .destructive) { (action) in
            self.audioManager.applyTrim()
        }
        
        let cancel = UIAlertAction(title: "Not yet", style: .cancel, handler: nil)
        alert.addAction(crop)
        alert.addAction(cancel)
        present(alert, animated: true, completion: nil)
    }
    
    func trimViewDidCancelTrim(_ view: TrimmableSoundwaveView) {
        audioManager.cancelTrim()
    }
}

extension ViewController: AudioManagerObserver {
    func audioPlayer(_ player: AudioManager, progressedWithTime time: TimeInterval) {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.allowedUnits = [ .hour, .minute, .second ]
        formatter.zeroFormattingBehavior = [ .pad ]
        let durationString = formatter.string(from: time) ?? "\(time)"
        lblTimer.text = durationString
    }
    
    func audioPlayer(_ player: AudioManager, didStartPlaying item: AudioItem) {
        btnPlayback.setImage(UIImage(named: "pause-button"), for: .normal)
    }
    
    func audioPlayer(_ player: AudioManager, didPausePlaybackOf item: AudioItem) {
        btnPlayback.setImage(UIImage(named: "play-button"), for: .normal)
    }
    
    func audioPlayerDidStop(_ player: AudioManager) {
        btnPlayback.setImage(UIImage(named: "play-button"), for: .normal)
    }
    
    func audioPlayer(_ player: AudioManager, didCreateTrimmedItem item: AudioItem) {
        lblTimer.text = "00:00:00"
    }
    
    func audioPlayer(_ player: AudioManager, didApplyTrimmedItem item: AudioItem) {
        lblTimer.text = "00:00:00"
        toggleTrimView()
    }
    
    func audioPlayerDidCancelTrim(_ player: AudioManager) {
        lblTimer.text = "00:00:00"
        toggleTrimView()
    }
}

extension UIView {
    func addShadow() {
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.5
        layer.shadowRadius = 2.0
        layer.shadowOffset = CGSize(width: 0.0, height: 1.0)
        layer.masksToBounds = false
        layer.rasterizationScale = UIScreen.main.scale
        layer.shouldRasterize = true
    }
    
    func removeShadow() {
        layer.shadowColor = nil
        layer.shadowOffset = .zero
        layer.shadowRadius = 0
        layer.shadowOpacity = 0
        layer.zPosition = 0
    }
}

extension ViewController: UIDocumentInteractionControllerDelegate {
    func documentInteractionControllerDidDismissOpenInMenu(_ controller: UIDocumentInteractionController) {
    }
}

// MARK: For later.
extension ViewController {
    func shareage() {
        if let audioURL4 = Bundle.main.url(forResource: "test" , withExtension: "m4a"), let image = UIImage(named: "speezy") {
            
            VideoGenerator.fileName = "Speezy Audio File"
            VideoGenerator.shouldOptimiseImageForVideo = true
            VideoGenerator.current.generate(withImages: [image], andAudios: [audioURL4], andType: .single, { (progress) in
                print(progress)
            }, outcome: { (outcome) in
                switch outcome {
                case let .success(url):
                    DispatchQueue.main.async {
                        self.sendToWhatsApp(url: url)
                    }
                case let .failure(error):
                    print("FAILED \(error.localizedDescription)")
                    return
                }
            })
        } else {
            
        }
    }
    
    func sendToWhatsApp(url: URL) {
        if let aString = URL(string: "whatsapp://app") {
            if UIApplication.shared.canOpenURL(aString) {
                documentInteractionController = UIDocumentInteractionController(url: url)
                documentInteractionController?.uti = "net.whatsapp.video"
                documentInteractionController?.delegate = self
                documentInteractionController?.annotation = "Test"
                documentInteractionController?.presentOpenInMenu(
                    from: CGRect(x: 0, y: 0, width: 0, height: 0),
                    in: view,
                    animated: true
                )
            } else {
                let alert = UIAlertController(
                    title: "Error",
                    message: "No WhatsApp installed on your iPhone",
                    preferredStyle: .alert
                )
                
                let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
                alert.addAction(ok)
                present(alert, animated: true, completion: nil)
            }
        }
    }
}
