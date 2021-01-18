//
//  ChatViewController.swift
//  Speezy
//
//  Created by Matt Beaney on 11/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import UIKit

class ChatViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    let viewModel = ChatViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel.didChange = { change in
            DispatchQueue.main.async {
                switch change {
                case .loaded:
                    self.collectionView.reloadData()
                case .itemInserted(_):
                    self.collectionView.insertItems(at: [IndexPath(item: 0, section: 0)])
                }
            }
        }
        
        collectionView.transform = CGAffineTransform(scaleX: 1, y: -1)
        collectionView.register(MessageCell.nib, forCellWithReuseIdentifier: "cell")
        collectionView.delegate = self
        collectionView.dataSource = self
        
        viewModel.listenForData()
    }
    
    @IBAction func addChatItem(_ sender: Any) {
        
    }
    
    @IBAction func addYouItem(_ sender: Any) {
        
    }
}

extension ChatViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewModel.items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! MessageCell
        let cellModel = viewModel.items[indexPath.row]
        cell.configure(item: cellModel)
        cell.contentView.transform = CGAffineTransform(scaleX: 1, y: -1)
        return cell
    }
}

extension ChatViewController: UICollectionViewDelegate {
    
}

extension ChatViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let preferredWidth = collectionView.frame.width
        let cellModel = viewModel.items[indexPath.row]
        let cell = MessageCell.createFromNib()
        
        cell.frame.size.width = preferredWidth
        cell.configure(item: cellModel)
        cell.setNeedsLayout()
        cell.layoutIfNeeded()
        
        let size = cell.systemLayoutSizeFitting(
            CGSize(
                width: preferredWidth,
                height: UIView.layoutFittingCompressedSize.height
            )
        )
        
        return CGSize(width: preferredWidth, height: size.height)
    }
}
