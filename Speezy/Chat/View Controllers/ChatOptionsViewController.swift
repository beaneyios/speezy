//
//  ChatOptionsViewController.swift
//  Speezy
//
//  Created by Matt Beaney on 12/05/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import UIKit
import SwipeCellKit

protocol ChatOptionsViewControllerDelegate: AnyObject {
    func chatOptionsViewControllerDidDeleteChat(_ viewController: ChatOptionsViewController)
    func chatOptionsViewControllerDidPop(_ viewController: ChatOptionsViewController)
}

class ChatOptionsViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    var viewModel: ChatOptionsViewModel!
    weak var delegate: ChatOptionsViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureCollectionView()
        
        viewModel.didChange = { change in
            DispatchQueue.main.async {
                switch change {
                case .updated:
                    self.collectionView.reloadData()
                case .chatDeleted:
                    self.delegate?.chatOptionsViewControllerDidDeleteChat(self)
                }
            }
        }
    }
    
    private func configureCollectionView() {
        collectionView.register(
            ChatterCell.nib,
            forCellWithReuseIdentifier: "cell"
        )
        
        collectionView.delegate = self
        collectionView.dataSource = self
    }
}

extension ChatOptionsViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewModel.chatters.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! ChatterCell
        let chatter = viewModel.chatters[indexPath.row]
        let cellModel = ChatterCellModel(
            chatter: chatter,
            isAdmin: viewModel.userIsAdmin(chatter: chatter)
        )
        cell.configure(viewModel: cellModel)
        
        if viewModel.canRemoveUsers {
            cell.delegate = self
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: collectionView.frame.width, height: 50.0)
    }
}

extension ChatOptionsViewController: SwipeCollectionViewCellDelegate {
    func collectionView(
        _ collectionView: UICollectionView,
        editActionsOptionsForItemAt indexPath: IndexPath,
        for orientation: SwipeActionsOrientation
    ) -> SwipeOptions {
        var options = SwipeOptions()
        options.transitionStyle = SwipeTransitionStyle.border
        return options
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        editActionsForItemAt indexPath: IndexPath,
        for orientation: SwipeActionsOrientation
    ) -> [SwipeAction]? {
        guard orientation == .right else {
            return []
        }
        
        let delete = SwipeAction(style: .destructive, title: "Remove") { (action, indexPath) in
            let alert = UIAlertController(
                title: "Confirm deletion",
                message: "Are you sure you want to remove this contact? They will be removed from the chat.",
                preferredStyle: .alert
            )
                        
            let delete = UIAlertAction(title: "Remove", style: .destructive) { _ in
                let chatter = self.viewModel.chatters[indexPath.row]
                self.viewModel.removeUser(chatter: chatter)
            }
            
            let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            
            alert.addAction(delete)
            alert.addAction(cancel)
            self.present(alert, animated: true, completion: nil)
        }
        
        delete.hidesWhenSelected = true
        delete.highlightedBackgroundColor = .speezyDarkRed
        
        return [delete]
    }
}
