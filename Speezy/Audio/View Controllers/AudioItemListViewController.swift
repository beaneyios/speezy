//
//  AudioItemListViewController.swift
//  Speezy
//
//  Created by Matt Beaney on 20/07/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import Foundation
import UIKit
import SCLAlertView
import Hero

protocol AudioItemListViewControllerDelegate: AnyObject {
    func audioItemListViewController(_ viewController: AudioItemListViewController, didSelectAudioItem item: AudioItem)
    func audioItemListViewControllerDidSelectCreateNewItem(_ viewController: AudioItemListViewController)
    func audioItemListViewControllerDidSelectSettings(_ viewController: AudioItemListViewController)
    func audioItemListViewController(_ viewController: AudioItemListViewController, didSelectSendOnItem item: AudioItem)
}

class AudioItemListViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var btnRecord: UIButton!
    @IBOutlet weak var gradient: UIImageView!
    
    var shareAlert: SCLAlertView?
    var documentInteractionController: UIDocumentInteractionController?
    
    lazy var shareController = AudioShareController(parentViewController: self)
    
    weak var delegate: AudioItemListViewControllerDelegate?
    var audioItems: [AudioItem] = []
    
    private var audioAttachmentManager = AudioAttachmentManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 91.0, right: 0)
        tableView.estimatedRowHeight = 100.0
        tableView.register(UINib(nibName: "AudioItemCell", bundle: nil), forCellReuseIdentifier: "cell")
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        
        hero.isEnabled = true
        btnRecord.hero.id = "record"
        
        loadItems()
    }
    
    private func loadItems() {
        audioItems = AudioStorage.fetchItems()
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }        
    }
    
    @IBAction func settingsTapped(_ sender: Any) {
        delegate?.audioItemListViewControllerDidSelectSettings(self)
    }
    
    @IBAction func speezyTapped(_ sender: Any) {
        delegate?.audioItemListViewControllerDidSelectCreateNewItem(self)
    }
    
    func reloadItem(_ item: AudioItem) {
        if audioItems.contains(item) {
            audioItems = audioItems.replacing(item)
        } else {
            audioItems.append(item)
        }
        
        audioAttachmentManager.resetCache()
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
}

extension AudioItemListViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        audioItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let audioItem = audioItems[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as! AudioItemCell
        cell.configure(with: audioItem, audioAttachmentManager: audioAttachmentManager)
        cell.delegate = self
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let audioItem = audioItems[indexPath.row]
        delegate?.audioItemListViewController(self, didSelectAudioItem: audioItem)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let item = self.audioItems[indexPath.row]
            deleteItem(item: item) {
                self.audioItems.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
        }
    }
    
    private func deleteItem(item: AudioItem, completion: @escaping () -> Void) {
        let appearance = SCLAlertView.SCLAppearance(kButtonFont: UIFont.systemFont(ofSize: 16.0, weight: .light), showCloseButton: false)
        let alert = SCLAlertView(appearance: appearance)
        
        alert.addButton("Delete", backgroundColor: UIColor(named: "alert-button-colour")!, textColor: UIColor(named: "speezy-red")) {
            self.audioAttachmentManager.storeAttachment(nil, forItem: item, completion: {})
            FileManager.default.deleteExistingURL(item.url)
            AudioStorage.deleteItem(item)
            completion()
        }
        
        alert.addButton("Cancel", backgroundColor: UIColor(named: "alert-button-colour")!, textColor: .blue) {}
        alert.showWarning("Delete item", subTitle: "Are you sure you want to delete this clip? You will not be able to undo this action.", closeButtonTitle: "Not yet")
    }
}

extension AudioItemListViewController: AudioItemCellDelegate {
    func audioItemCell(_ cell: AudioItemCell, didTapMoreOptionsWithItem item: AudioItem) {
        let alert = UIAlertController(title: "More options", message: nil, preferredStyle: .actionSheet)
        let shareAction = UIAlertAction(title: "Share", style: .default) { (action) in
            self.share(item: item)
        }
        
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { (action) in
            self.deleteItem(item: item, completion: {
                self.audioItems = self.audioItems.removing(item)
                self.tableView.reloadData()
            })
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(shareAction)
        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    func share(item: AudioItem) {
        delegate?.audioItemListViewController(self, didSelectSendOnItem: item)
    }
}
