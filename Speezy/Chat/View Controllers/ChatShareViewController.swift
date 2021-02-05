//
//  ChatShareViewController.swift
//  Speezy
//
//  Created by Matt Beaney on 05/02/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import UIKit

protocol ChatShareViewControllerDelegate: AnyObject {
    func chatShareViewController(
        _ viewController: ChatShareViewController,
        didSelectChat chat: Chat
    )
    
    func chatShareViewControllerDidSelectExit(
        _ viewController: ChatShareViewController
    )
}

class ChatShareViewController: UIViewController {
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var emptyView: UIView!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    var viewModel: ChatShareViewModel!
    weak var delegate: ChatShareViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureCollectionView()
        listenForChanges()
        
        collectionView.alpha = 0.0
    }
    
    @IBAction func didTapClose(_ sender: Any) {
        delegate?.chatShareViewControllerDidSelectExit(self)
    }
    
    private func listenForChanges() {
        viewModel.didChange = { change in
            self.applyChange(change: change)
        }

        viewModel.fetchChats()
    }
    
    private func applyChange(change: ChatShareViewModel.Change) {
        DispatchQueue.main.async {            
            switch change {
            case .loaded:
                self.toggleEmptyView()
                self.collectionView.reloadData()
                
                UIView.animate(withDuration: 0.3) {
                    self.collectionView.alpha = 1.0
                }
            case let .loading(isLoading):
                if isLoading {
                    self.sendButton.isHidden = true
                    self.spinner.startAnimating()
                    self.spinner.isHidden = false
                } else {
                    self.sendButton.isHidden = false
                    self.spinner.stopAnimating()
                    self.spinner.isHidden = true
                }
            case let .selectChat(chat):
                self.delegate?.chatShareViewController(self, didSelectChat: chat)
            }
        }
    }
    
    private func toggleEmptyView() {
        if viewModel.shouldShowEmptyView {
            emptyView.isHidden = false
        } else {
            emptyView.isHidden = true
        }
    }
    
    private func configureCollectionView() {
        collectionView.register(
            ChatSelectionCell.nib,
            forCellWithReuseIdentifier: "cell"
        )
        
        collectionView.allowsMultipleSelection = true
        collectionView.delegate = self
        collectionView.dataSource = self
    }
}

extension ChatShareViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewModel.items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! ChatSelectionCell
        let cellModel = viewModel.items[indexPath.row]
        cell.configure(item: cellModel)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = viewModel.items[indexPath.row]
        viewModel.selectChat(chat: item.chat)
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let item = viewModel.items[indexPath.row]
        viewModel.selectChat(chat: item.chat)
    }
}

extension ChatShareViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        CGSize(width: collectionView.frame.width, height: 80.0)
    }
}
