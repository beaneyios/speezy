//
//  AudioShareable.swift
//  Speezy
//
//  Created by Matt Beaney on 25/07/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import Foundation
import SwiftVideoGenerator
import SCLAlertView

protocol AudioShareable: AnyObject {
    var shareAlert: SCLAlertView? { get set }
    var documentInteractionController: UIDocumentInteractionController? { get set }
    func share(item: AudioItem, attachmentImage: UIImage?, completion: (() -> Void)?)
}

extension AudioShareable where Self: UIViewController {
    func share(item: AudioItem, attachmentImage: UIImage?, completion: (() -> Void)?) {
        let appearance = SCLAlertView.SCLAppearance(showCloseButton: false)
        let alert = SCLAlertView(appearance: appearance)
        alert.showInfo(
            "Preparing your video to share",
            subTitle: "This should only take a few seconds"
        )
        shareAlert = alert
        
        var images = [UIImage]()
        
        if let attachmentImage = attachmentImage {
            let videoPlaceholder = CustomVideoPlaceholderView.createFromNib()
            
            let ratio = attachmentImage.size.width / attachmentImage.size.height
            videoPlaceholder.frame.size.height = videoPlaceholder.frame.width / ratio
            videoPlaceholder.configure(with: item, attachmentImage: attachmentImage)
            videoPlaceholder.setNeedsLayout()
            videoPlaceholder.layoutIfNeeded()
            images.append(videoPlaceholder.asImage())
        } else {
            let videoPlaceholder = VideoPlaceholderView.createFromNib()
            videoPlaceholder.configure(with: item)
            videoPlaceholder.setNeedsLayout()
            videoPlaceholder.layoutIfNeeded()
            images.append(videoPlaceholder.asImage())
        }
        
        let audioURL = item.url
        VideoGenerator.fileName = "Speezy Audio File"
        VideoGenerator.shouldOptimiseImageForVideo = true
        VideoGenerator.current.generate(withImages: images, andAudios: [audioURL], andType: .single, { (progress) in
            print(progress)
        }, outcome: { (outcome) in
            switch outcome {
            case let .success(url):
                DispatchQueue.main.async {
                    self.shareAlert?.hideView()
                    self.shareAlert = nil
                    self.sendToWhatsApp(url: url)
                    completion?()
                }
            case let .failure(error):
                print("FAILED \(error.localizedDescription)")
                return
            }
        })
    }
    
    func sendToWhatsApp(url: URL) {
        documentInteractionController = UIDocumentInteractionController(url: url)
        documentInteractionController?.uti = "net.whatsapp.video"
        documentInteractionController?.annotation = "Test"
        documentInteractionController?.presentOpenInMenu(
            from: CGRect(x: 0, y: 0, width: 0, height: 0),
            in: view,
            animated: true
        )
    }
}
