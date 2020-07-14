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
    @IBOutlet weak var trimmableWaveContainer: UIView!
    
    private var mainWave: LargeSoundwaveView?
    
    var documentInteractionController: UIDocumentInteractionController?
    
    let audioManager = AudioManager(
        item: AudioItem(url: Bundle.main.url(forResource: "test", withExtension: "m4a")!)
    )
            
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpSoundWaves()
        
        audioManager.addObserver(self)
    }
    
    @IBAction func toggleRecording(_ sender: Any) {
        btnRecord.setImage(UIImage(named: "stop-recording-button"), for: .normal)
    }
    
    @IBAction func toggleCrop(_ sender: Any) {
        
    }
    
    @IBAction func togglePlayback(_ sender: Any) {
        audioManager.togglePlayback()
    }
    
    @IBAction func toggleCut(_ sender: Any) {
    }
    
    func setUpSoundWaves() {
        setUpMainSoundwave()
        setUpTrimmableSoundwave()
    }
    
    func setUpTrimmableSoundwave() {
        let trimmableSoundwaveView = TrimmableSoundwaveView.instanceFromNib()
        trimmableWaveContainer.addSubview(trimmableSoundwaveView)
        
        trimmableSoundwaveView.snp.makeConstraints { (maker) in
            maker.edges.equalTo(self.trimmableWaveContainer)
        }
        
        trimmableSoundwaveView.configure(manager: audioManager)
    }
    
    func setUpMainSoundwave() {
        let soundWaveView = LargeSoundwaveView.instanceFromNib()
        mainWaveContainer.addSubview(soundWaveView)
        
        soundWaveView.snp.makeConstraints { (maker) in
            maker.edges.equalTo(self.mainWaveContainer)
        }
        
        soundWaveView.configure(manager: audioManager)
        mainWave = soundWaveView
    }
    
    @IBAction func go(_ sender: Any) {
        trimmage()
    }
    
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
    
    func trimmage() {
        let editor = AudioEditor()
        editor.trim(fileURL: audioManager.item.url, startTime: 1, stopTime: 4) { (outputURL) in
            
            DispatchQueue.main.async {
                self.setUpSoundWaves()
            }
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
                let alert = UIAlertController(title: "Error", message: "No WhatsApp installed on your iPhone", preferredStyle: .alert)
                let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
                alert.addAction(ok)
                present(alert, animated: true, completion: nil)
            }
        }
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
}

extension ViewController: UIDocumentInteractionControllerDelegate {
    func documentInteractionControllerDidDismissOpenInMenu(_ controller: UIDocumentInteractionController) {
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
