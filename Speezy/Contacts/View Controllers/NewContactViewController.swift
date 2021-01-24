//
//  NewContactViewController.swift
//  Speezy
//
//  Created by Matt Beaney on 24/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import UIKit

protocol NewContactViewControllerDelegate: AnyObject {
    func newContactViewController(_ viewController: NewContactViewController, didCreateContact contact: Contact)
}

class NewContactViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var createSpinner: UIActivityIndicatorView!
    
    weak var delegate: NewContactViewControllerDelegate?
    
    let viewModel = NewContactViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureCollectionView()
        listenForChanges()
        
        titleTextField.isUserInteractionEnabled = false
        titleTextField.delegate = self
    
        viewModel.loadData()
    }
    
    private func listenForChanges() {
        viewModel.didChange = { change in
            DispatchQueue.main.async {
                switch change {
                case .userLoaded:
                    self.titleTextField.isUserInteractionEnabled = true
                    self.createSpinner.isHidden = true
                    self.createSpinner.stopAnimating()
                case .loaded:
                    self.collectionView.reloadData()
                case let .loading(isLoading):
                    if isLoading {
                        self.createSpinner.isHidden = false
                        self.createSpinner.startAnimating()
                    } else {
                        self.createSpinner.isHidden = true
                        self.createSpinner.stopAnimating()
                    }
                case let .contactAdded(contact):
                    self.delegate?.newContactViewController(self, didCreateContact: contact)
                }
            }
        }
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

extension NewContactViewController: UITextFieldDelegate {
    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        
        guard let textFieldText = textField.text else {
            return true
        }
        
        let nsText = textFieldText as NSString
        let newString = nsText.replacingCharacters(
            in: range,
            with: string
        )
        
        viewModel.setUserName(userName: newString)
        return true
    }
}

extension NewContactViewController: UICollectionViewDataSource, UICollectionViewDelegate {
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
        viewModel.addContact(contact: item.contact)
    }
}

extension NewContactViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        CGSize(width: collectionView.frame.width, height: 80.0)
    }
}
