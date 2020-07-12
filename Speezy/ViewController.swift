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
    
    @IBOutlet weak var waveImage: UIImageView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var share: UIButton!
    
    @IBOutlet weak var leftHandle: UIView!
    @IBOutlet weak var rightHandle: UIView!
    
    @IBOutlet weak var leftHandleConstraint: NSLayoutConstraint!
    @IBOutlet weak var rightHandleConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var waveContainer: UIView!
    
    var documentInteractionController: UIDocumentInteractionController?
    
    var currentFileURL = Bundle.main.url(forResource: "test", withExtension: "m4a")
    
    private var lastLeftLocation: CGFloat = 16.0
    private var lastRightLocation: CGFloat = 16.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        spinner.isHidden = true
        share.layer.cornerRadius = 22.5
        share.backgroundColor = .red
        share.setTitleColor(.white, for: .normal)
        share.addShadow()
        setUpSoundWaves()
        setUpHandles()
    }
    
    func setUpHandles() {
        let panRight = UIPanGestureRecognizer(target: self, action: #selector(rightPan(sender:)))
        rightHandle.addGestureRecognizer(panRight)
        
        let panLeft = UIPanGestureRecognizer(target: self, action: #selector(leftPan(sender:)))
        leftHandle.addGestureRecognizer(panLeft)
    }
    
    @objc func leftPan(sender: UIPanGestureRecognizer) {
        view.layoutIfNeeded()
        
        let translation = sender.translation(in: waveContainer)
        let newConstraint = lastLeftLocation + translation.x
        
        if sender.state == .changed {
            if newConstraint < 0 {
                leftHandleConstraint.constant = 0.0
                lastLeftLocation = 0.0
                return
            }
            
            if (newConstraint + 48.0) > rightHandle.frame.minX {
                return
            }
            
            leftHandleConstraint.constant = newConstraint
            view.layoutIfNeeded()
        }
        
        if sender.state == .ended {
            lastLeftLocation = newConstraint
        }
    }
    
    @objc func rightPan(sender: UIPanGestureRecognizer) {
        view.layoutIfNeeded()
        
        let translation = sender.translation(in: waveContainer)
        let newConstraint = lastRightLocation - translation.x
        
        if sender.state == .changed {
            if newConstraint < 0 {
                rightHandleConstraint.constant = 0.0
                lastRightLocation = 0.0
                return
            }
            
            if (newConstraint + 48.0) > (waveContainer.frame.width - leftHandle.frame.maxX) {
                return
            }
            
            rightHandleConstraint.constant = newConstraint
            view.layoutIfNeeded()
        }
        
        if sender.state == .ended {
            lastRightLocation = newConstraint
        }
    }
    
    func setUpSoundWaves() {
        let soundWaveView = LargeSoundwaveView.instanceFromNib()
        waveContainer.addSubview(soundWaveView)
        
        soundWaveView.snp.makeConstraints { (maker) in
            maker.edges.equalTo(self.waveContainer)
        }
        
        soundWaveView.configure(with: currentFileURL!)
    }
    
    @IBAction func go(_ sender: Any) {
        trimmage()
    }
    
    func shareage() {
        share.setTitle("SHARING...", for: .normal)
        spinner.isHidden = false
        spinner.startAnimating()
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
        share.setTitle("SHARE", for: .normal)
        spinner.isHidden = true
        spinner.stopAnimating()
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
