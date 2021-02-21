//
//  ImportContactViewController.swift
//  Speezy
//
//  Created by Matt Beaney on 20/02/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import UIKit

protocol ImportContactViewControllerDelegate: AnyObject {
    func importContactViewController(_ viewController: ImportContactViewController, didImportContact contact: Contact)
}

class ImportContactViewController: UIViewController {
    
    @IBOutlet weak var speezyLoadingContainer: UIView!
    private var loadingView: SpeezyLoadingView?
    
    var viewModel: ImportContactViewModel!
    weak var delegate: ImportContactViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureLoader()
        startLoading()
        
        viewModel.didChange = { change in
            DispatchQueue.main.async {
                switch change {
                case let .contactImported(contact):
                    self.delegate?.importContactViewController(self, didImportContact: contact)
                }
            }
        }
        
        viewModel.loadData()
    }
    
    private func configureLoader() {
        speezyLoadingContainer.isHidden = true
        let loading = SpeezyLoadingView.createFromNib()
        speezyLoadingContainer.addSubview(loading)
        
        loading.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        loadingView = loading
    }
    
    private func startLoading() {
        speezyLoadingContainer.isHidden = false
        loadingView?.startAnimating()
    }
    
    func stopLoading(completion: @escaping () -> Void) {
        self.loadingView?.stopAnimating()
    }
}
