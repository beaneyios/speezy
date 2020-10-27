//
//  TranscriptionButton.swift
//  Speezy
//
//  Created by Matt Beaney on 27/10/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import UIKit

class TranscriptionButton: UIView, NibLoadable {
    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var loadingContainer: UIView!
    @IBOutlet weak var buttonTapped: UIButton!
    
    enum State {
        case loading
        case successful
        case normal
    }
    
    var action: (() -> Void)?
    
    private var loadingView: SpeezyLoadingView?
    private var state: State = .normal
    
    override func awakeFromNib() {
        super.awakeFromNib()
        loadingContainer.isHidden = true
    }
    
    func switchToLoading() {
        if state == .loading {
            return
        }
        
        state = .loading
        loadingContainer.isHidden = false
        let loading = SpeezyLoadingView.createFromNib()
        loading.barTintColor = .white
        loadingContainer.addSubview(loading)
        
        loading.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        loadingView = loading
        loading.startAnimating()
        
        image.image = UIImage(named: "transcription-button-loading")
    }
    
    func switchToSuccessful() {
        state = .successful
        
        loadingView?.stopAnimating()
        loadingContainer.isHidden = true
        image.image = UIImage(named: "transcription-button-success")
    }
    
    func switchToNormal() {
        state = .normal
        
        loadingView?.stopAnimating()
        loadingContainer.isHidden = true
        image.image = UIImage(named: "transcription-button")
    }
    
    @IBAction func buttonTapped(_ sender: Any) {
        action?()
    }
}
