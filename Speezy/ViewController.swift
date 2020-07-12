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
import DSWaveformImage
import SoundWave

class ViewController: UIViewController {
    
    @IBOutlet weak var recordButtonContainer: UIView!
    @IBOutlet weak var recordButton: UIButton!
    
    @IBOutlet weak var waveContainer: UIView!
    @IBOutlet weak var trimmableWaveContainer: UIView!
    
    var documentInteractionController: UIDocumentInteractionController?
    
    var currentFileURL = Bundle.main.url(forResource: "test", withExtension: "m4a")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpSoundWaves()
        configureRecordButton()
    }
    
    func configureRecordButton() {
        view.setNeedsLayout()
        recordButtonContainer.layer.cornerRadius = recordButtonContainer.frame.width / 2.0
        recordButtonContainer.layer.borderWidth = 0.5
        recordButtonContainer.layer.borderColor = UIColor.white.cgColor
        
        recordButton.layer.cornerRadius = recordButton.frame.width / 2.0
    }
    
    @IBAction func startRecording(_ sender: Any) {
        
    }
    
    func setUpSoundWaves() {
        let soundWaveView = LargeSoundwaveView.instanceFromNib()
        waveContainer.addSubview(soundWaveView)
        
        soundWaveView.snp.makeConstraints { (maker) in
            maker.edges.equalTo(self.waveContainer)
        }
        
        soundWaveView.configure(with: currentFileURL!)
        
        let trimmableSoundwaveView = TrimmableSoundwaveView.instanceFromNib()
        trimmableWaveContainer.addSubview(trimmableSoundwaveView)
        
        trimmableSoundwaveView.snp.makeConstraints { (maker) in
            maker.edges.equalTo(self.trimmableWaveContainer)
        }
        
        trimmableSoundwaveView.configure(with: currentFileURL!)
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
        guard let audioURL = currentFileURL else {
            return
        }
        
        let editor = AudioEditor()
        editor.trim(fileURL: audioURL, startTime: 1, stopTime: 4) { (outputURL) in
            self.currentFileURL = outputURL
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
