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
import MessageUI

class AudioShareController: NSObject {
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
        
        if config.attachment != nil || config.includeTags || config.includeTitle {
            generateVideoAndPresentShareOption(item: audioItem, option: option, config: config)
        } else {
            generateAudioAndPresentShareOption(item: audioItem, option: option)
        }
    }
    
    func shareViewControllerShouldPop(_ shareViewController: ShareViewController) {
        dismissCustomShareDialogue(shareViewController: shareViewController)
    }
}

extension AudioShareController {
    func generateAudioAndPresentShareOption(item: AudioItem, option: ShareOption) {
        presentShareOption(url: item.fileUrl, option: option)
    }
    
    func generateVideoAndPresentShareOption(item: AudioItem, option: ShareOption, config: ShareConfig) {
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
            videoPlaceholder.configure(with: item, config: config)
            videoPlaceholder.setNeedsLayout()
            videoPlaceholder.layoutIfNeeded()
            
            let changeFrequency = Int(item.calculatedDuration / 10.0)
            
            if changeFrequency > 0 {
                images = (1...changeFrequency).map {
                    if ($0 % 2) == 0 {
                        videoPlaceholder.attributionHeight.constant = 0.0
                        videoPlaceholder.lblAttribution.text = ""
                    } else {
                        videoPlaceholder.attributionHeight.constant = 21.0
                        videoPlaceholder.lblAttribution.text = "Audio Clip Created by Speezy"
                    }
                    
                    videoPlaceholder.setNeedsLayout()
                    videoPlaceholder.layoutIfNeeded()
                    
                    return videoPlaceholder.asImage()
                }
            } else {
                images.append(videoPlaceholder.asImage())
            }
        } else {
            let videoPlaceholder = VideoPlaceholderView.createFromNib()
            videoPlaceholder.configure(with: item, config: config)
            videoPlaceholder.setNeedsLayout()
            videoPlaceholder.layoutIfNeeded()
            
            let changeFrequency = Int(item.calculatedDuration / 10.0)
            
            if changeFrequency > 0 {
                images = (1...changeFrequency).map {
                    if ($0 % 2) == 0 {
                        videoPlaceholder.attributionHeight.constant = 0.0
                        videoPlaceholder.lblAttribution.text = ""
                    } else {
                        videoPlaceholder.attributionHeight.constant = 21.0
                        videoPlaceholder.lblAttribution.text = "Audio Clip Created by Speezy"
                    }
                    
                    videoPlaceholder.setNeedsLayout()
                    videoPlaceholder.layoutIfNeeded()
                    
                    return videoPlaceholder.asImage()
                }
            } else {
                images.append(videoPlaceholder.asImage())
            }
        }
        
        let audioURL = item.fileUrl
        VideoGenerator.fileName = "Speezy Audio File"
        VideoGenerator.shouldOptimiseImageForVideo = true
        VideoGenerator.current.generate(withImages: images, andAudios: [audioURL], andType: .singleAudioMultipleImage, { (progress) in
            print(progress)
        }, outcome: { (outcome) in
            switch outcome {
            case let .success(url):
                DispatchQueue.main.async {
                    self.shareAlert?.hideView()
                    self.shareAlert = nil
                    self.presentShareOption(url: url, option: option)
                    self.completion?()
                }
            case let .failure(error):
                print("FAILED \(error.localizedDescription)")
                return
            }
        })
    }
    
    func presentShareOption(url: URL, option: ShareOption) {
        switch option.platform {
        case .email:
            sendEmail(url: url)
        default:
            presentNativeShareSheet(url: url)
        }
    }
    
    func presentNativeShareSheet(url: URL) {
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

extension AudioShareController: MFMailComposeViewControllerDelegate {
    func sendEmail(url: URL) {
        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            let tagsText = audioItem.tags.map {
                "<p>#\($0.title)</p>"
            }.joined()
            mail.setMessageBody("<p>Audio shared from Speezy</p><p>\(audioItem.title)</p>\(tagsText)", isHTML: true)
            
            if let data = try? Data(contentsOf: url) {
                mail.addAttachmentData(data, mimeType: "video/mp4    ", fileName: "\(audioItem.title).m4v")
            }

            parentViewController?.present(mail, animated: true)
        } else {
            // show failure alert
        }
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
}
