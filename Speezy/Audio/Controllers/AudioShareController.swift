//
//  AudioShareController.swift
//  Speezy
//
//  Created by Matt Beaney on 23/08/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import UIKit
import SCLAlertView
import SwiftVideoGenerator

class AudioShareController {
    typealias ShareCompletion = () -> Void
    
    weak var parentViewController: UIViewController?
    
    private var audioItem: AudioItem!
    private var shareAlert: SCLAlertView!
    private var config: ShareConfig!
    
    private var completion: ShareCompletion?
    private var documentInteractionController: UIDocumentInteractionController?
    
    init(parentViewController: UIViewController?) {
        self.parentViewController = parentViewController
    }
    
    func share(_ item: AudioItem, config: ShareConfig, completion: ShareCompletion?) {
        self.completion = completion
        self.audioItem = item
        self.config = config
        
        presentCustomShareDialogue()
    }
}

extension AudioShareController: ShareViewControllerDelegate {
    private func presentCustomShareDialogue() {
        let storyboard = UIStoryboard(name: "Audio", bundle: nil)
        let shareViewController = storyboard.instantiateViewController(identifier: "ShareViewController") as! ShareViewController
        parentViewController?.addChild(shareViewController)
        parentViewController?.view.addSubview(shareViewController.view)
        
        shareViewController.view.layer.cornerRadius = 10.0
        shareViewController.view.clipsToBounds = true
        shareViewController.view.addShadow()
        
        shareViewController.view.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        shareViewController.delegate = self
    }
    
    private func dismissCustomShareDialogue(shareViewController: ShareViewController) {
        shareViewController.view.removeFromSuperview()
        shareViewController.removeFromParent()
        shareViewController.willMove(toParent: nil)
    }
    
    func shareViewController(_ shareViewController: ShareViewController, didSelectOption option: ShareOption) {
        shareViewController.dismissShare()
        
        switch option.platform {
        case .email:
            break
        default:
            presentNativeShareSheet(item: audioItem, config: config)
        }
    }
    
    func shareViewControllerShouldPop(_ shareViewController: ShareViewController) {
        dismissCustomShareDialogue(shareViewController: shareViewController)
    }
}

extension AudioShareController {
    func presentNativeShareSheet(item: AudioItem, config: ShareConfig) {
        let appearance = SCLAlertView.SCLAppearance(showCloseButton: false)
        let alert = SCLAlertView(appearance: appearance)
        alert.showInfo(
            "Preparing your video to share",
            subTitle: "This should only take a few seconds"
        )
        shareAlert = alert
        
        var images = [UIImage]()
        
        if let attachmentImage = config.attachment {
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
                    self.sendToCustomShareSheet(url: url)
                    self.completion?()
                }
            case let .failure(error):
                print("FAILED \(error.localizedDescription)")
                return
            }
        })
    }
    
    func sendToCustomShareSheet(url: URL) {
        guard let parentViewController = self.parentViewController else {
            assertionFailure("No parent view controller, there should be")
            return
        }
        
        documentInteractionController = UIDocumentInteractionController(url: url)
        documentInteractionController?.presentOpenInMenu(
            from: CGRect(x: 0, y: 0, width: 0, height: 0),
            in: parentViewController.view,
            animated: true
        )
    }
}
