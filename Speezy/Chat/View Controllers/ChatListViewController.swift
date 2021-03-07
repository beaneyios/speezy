//
//  ChatListViewController.swift
//  Speezy
//
//  Created by Matt Beaney on 23/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import UIKit
import JGProgressHUD

protocol ChatListViewControllerDelegate: AnyObject {
    func chatListViewControllerDidSelectBack(_ viewController: ChatListViewController)
    func chatListViewController(_ viewController: ChatListViewController, didSelectChat chat: Chat)
    func chatListViewControllerDidSelectCreateNewChat(_ viewController: ChatListViewController)
}

class ChatListViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var emptyView: UIView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    weak var delegate: ChatListViewControllerDelegate?
        
    let viewModel = ChatListViewModel(store: Store.shared)
    
    private var hud: JGProgressHUD?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureCollectionView()
        listenForChanges()
        
        collectionView.alpha = 0.0
    }
    
    @IBAction func createNewChat(_ sender: Any) {
        delegate?.chatListViewControllerDidSelectCreateNewChat(self)
    }
    
    func navigateToChatId(_ chatId: String) {
        viewModel.navigateToChatId(chatId)
    }
    
    private func listenForChanges() {
        viewModel.didChange = { change in
            self.applyChange(change: change)
        }

        viewModel.listenForData()
    }
    
    private func applyChange(change: ChatListViewModel.Change) {        
        DispatchQueue.main.async {
            self.navigationController?.tabBarItem.image = UIImage(
                named: self.viewModel.anyUnreadChats ? "chat-tab-item-unread" : "chat-tab-item"
            )
            
            switch change {
            case .loaded:
                self.toggleEmptyView()
                self.collectionView.reloadData()
                
                UIView.animate(withDuration: 0.3) {
                    self.collectionView.alpha = 1.0
                }
            case let .loading(isLoading):
                if isLoading {
                    let hud = JGProgressHUD()
                    hud.textLabel.text = "Loading your chats..."
                    hud.show(in: self.view)
                    self.hud = hud
                    
                    self.spinner.startAnimating()
                    self.spinner.isHidden = false
                } else {
                    
                    self.hud?.dismiss()
                    self.spinner.stopAnimating()
                    self.spinner.isHidden = true
                }
            case let .replacedItem(cellModel, index):
                self.collectionView.visibleCells.forEach {
                    guard
                        let indexPath = self.collectionView.indexPath(for: $0),
                        let chatCell = $0 as? ChatCell,
                        indexPath.row == index
                    else {
                        return
                    }
                    
                    chatCell.configureNotificationLabel(item: cellModel)
                }
            case let .loadChat(chat):
                self.delegate?.chatListViewController(self, didSelectChat: chat)
            }
        }
    }
    
    private func toggleEmptyView() {
        if viewModel.shouldShowEmptyView && viewModel.loadingTimerHit {
            emptyView.isHidden = false
        } else {
            emptyView.isHidden = true
        }
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

