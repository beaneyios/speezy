//
//  LoremViewController.swift
//  Speezy
//
//  Created by Matt Beaney on 21/10/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import UIKit
import GhostTypewriter

class LoremCollectionViewController: UIViewController {
    
    @IBOutlet weak var titleLabel: TypewriterLabel!
    @IBOutlet weak var loadingContainer: UIView!
    private var loadingView: SpeezyLoadingView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureLoader()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 15

        let content = "Your transcript will be ready soon - it usually takes around half the length of your clip to transcribe"
        
        let attrString = NSMutableAttributedString(string: content)
        attrString.addAttribute(.paragraphStyle, value:paragraphStyle, range:NSMakeRange(0, attrString.length))

        titleLabel.attributedText = attrString
                
        titleLabel.typingTimeInterval = 0.05
        titleLabel.startTypewritingAnimation {
            DispatchQueue.main.async {
                self.restart()
            }
        }
        
        startLoading()
    }
    
    private func restart() {
        DispatchQueue.main.async {
            self.titleLabel.resetTypewritingAnimation()
            self.titleLabel.startTypewritingAnimation {
                self.restart()
            }
        }
    }
    
    private func configureLoader() {
        loadingContainer.isHidden = true
        let loading = SpeezyLoadingView.createFromNib()
        loadingContainer.addSubview(loading)
        
        loading.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        loadingView = loading
    }
    
    private func startLoading() {
        loadingContainer.isHidden = false
        self.loadingView?.startAnimating()
    }
    
    func stopLoading(completion: @escaping () -> Void) {
        self.loadingView?.restCompletion = {
            UIView.animate(withDuration: 0.9) {
                self.loadingView?.alpha = 0.0
            } completion: { (finished) in
                self.loadingContainer.isHidden = true
                completion()
            }
        }
        
        self.loadingView?.stopAnimating()
    }
}
