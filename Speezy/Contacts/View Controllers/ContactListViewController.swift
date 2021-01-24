//
//  ContactListViewController.swift
//  Speezy
//
//  Created by Matt Beaney on 23/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import UIKit

protocol ContactListViewControllerDelegate: AnyObject {
    func contactListViewControllerDidSelectBack(_ viewController: ContactListViewController)
    func contactListViewController(_ viewController: ContactListViewController, didSelectContact contact: Contact)
    func contactListViewControllerDidSelectNewContact(_ viewController: ContactListViewController)
}

class ContactListViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    weak var delegate: ContactListViewControllerDelegate?
    
    let viewModel = ContactListViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureCollectionView()
        listenForChanges()
    }
    
    func insertNewContactItem(contact: Contact) {
        viewModel.insertNewContactItem(contact: contact)
    }
    
    @IBAction func newContactTapped(_ sender: Any) {
        delegate?.contactListViewControllerDidSelectNewContact(self)
    }
    
    @IBAction func goBack(_ sender: Any) {
        delegate?.contactListViewControllerDidSelectBack(self)
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
            ContactCell.nib,
            forCellWithReuseIdentifier: "cell"
        )
        
        collectionView.delegate = self
        collectionView.dataSource = self
    }
}

extension ContactListViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewModel.items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! ContactCell
        let cellModel = viewModel.items[indexPath.row]
        cell.configure(item: cellModel)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = viewModel.items[indexPath.row]
        delegate?.contactListViewController(self, didSelectContact: item.contact)
    }
}

extension ContactListViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        CGSize(width: collectionView.frame.width, height: 80.0)
    }
}

