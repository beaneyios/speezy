//
//  AudioItemListViewController.swift
//  Speezy
//
//  Created by Matt Beaney on 20/07/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import Foundation
import UIKit

protocol AudioItemListViewControllerDelegate: AnyObject {
    func audioItemListViewController(_ viewController: AudioItemListViewController, didSelectAudioItem item: AudioItem)
    func audioItemListViewControllerDidSelectCreateNewItem(_ viewController: AudioItemListViewController)
}

class AudioItemListViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    
    weak var delegate: AudioItemListViewControllerDelegate?
    var audioItems: [AudioItem] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        let plusButton = UIBarButtonItem(image: UIImage(named: "settings-button"), style: .plain, target: self, action: #selector(newItemTapped))
        navigationItem.rightBarButtonItem = plusButton
        navigationItem.rightBarButtonItem?.tintColor = .black
        title = "My recordings"
        
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 91.0, right: 0)
        tableView.estimatedRowHeight = 100.0
        tableView.register(UINib(nibName: "AudioItemCell", bundle: nil), forCellReuseIdentifier: "cell")
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    @IBAction func speezyTapped(_ sender: Any) {
        delegate?.audioItemListViewControllerDidSelectCreateNewItem(self)
    }
    
    @objc func newItemTapped() {
        delegate?.audioItemListViewControllerDidSelectCreateNewItem(self)
    }
    
    func reloadItem(_ item: AudioItem) {
        if audioItems.contains(item) {
            audioItems = audioItems.replacing(item)
        } else {
            audioItems.append(item)
        }
        
        tableView.reloadData()
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
        cell.configure(with: audioItem)
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let audioItem = audioItems[indexPath.row]
        delegate?.audioItemListViewController(self, didSelectAudioItem: audioItem)
    }
    
    
}
