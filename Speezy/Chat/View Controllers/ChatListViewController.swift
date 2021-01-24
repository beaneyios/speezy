//
//  ChatListViewController.swift
//  Speezy
//
//  Created by Matt Beaney on 23/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import UIKit

protocol ChatListViewControllerDelegate: AnyObject {
    func chatListViewControllerDidSelectBack(_ viewController: ChatListViewController)
    func chatListViewController(_ viewController: ChatListViewController, didSelectChat chat: Chat)
    func chatListViewControllerDidSelectCreateNewChat(_ viewController: ChatListViewController)
}

class ChatListViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    weak var delegate: ChatListViewControllerDelegate?
    
    let viewModel = ChatListViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureCollectionView()
        listenForChanges()
    }
    
    @IBAction func createNewChat(_ sender: Any) {
        delegate?.chatListViewControllerDidSelectCreateNewChat(self)
    }
    
    @IBAction func goBack(_ sender: Any) {
        delegate?.chatListViewControllerDidSelectBack(self)
    }
    
    func insertNewChatItem(chat: Chat) {
        viewModel.insertNewChatItem(chat: chat)
    }
    
    private func listenForChanges() {
        viewModel.didChange = { change in
            DispatchQueue.main.async {
                switch change {
                case .loaded:
                    self.collectionView.reloadData()
                }
            }
        }

        viewModel.listenForData()
    }
    
    private func configureCollectionView() {
        collectionView.register(
            ChatCell.nib,
            forCellWithReuseIdentifier: "cell"
        )
        
        collectionView.delegate = self
        collectionView.dataSource = self
    }
}

extension ChatListViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewModel.items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! ChatCell
        let cellModel = viewModel.items[indexPath.row]
        cell.configure(item: cellModel)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = viewModel.items[indexPath.row]
        delegate?.chatListViewController(self, didSelectChat: item.chat)
    }
}

extension ChatListViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        CGSize(width: collectionView.frame.width, height: 80.0)
    }
}

