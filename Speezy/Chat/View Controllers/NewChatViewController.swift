//
//  NewChatViewController.swift
//  Speezy
//
//  Created by Matt Beaney on 23/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import UIKit

protocol NewChatViewControllerDelegate: AnyObject {
    func newChatViewController(_ viewController: NewChatViewController, didCreateChat chat: Chat)
    func newChatViewControllerDidSelectBack(_ viewController: NewChatViewController)
}

class NewChatViewController: UIViewController, FormErrorDisplaying {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var titleTextFieldSeparator: UIView!
    @IBOutlet weak var lblErrorMessage: UILabel?
    
    @IBOutlet weak var createSpinner: UIActivityIndicatorView!
    @IBOutlet weak var createButton: UIButton!
    @IBOutlet weak var emptyView: UIView!
    
    @IBOutlet var keyboardBottomConstraints: [NSLayoutConstraint]!
    
    weak var delegate: NewChatViewControllerDelegate?
    
    var fieldDict: [Field : UIView] {
        [Field.chatTitle: titleTextFieldSeparator]
    }
    
    var separators: [UIView] {
        [titleTextFieldSeparator]
    }
    
    let viewModel = NewChatViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureCollectionView()
        listenForChanges()
        
        titleTextField.delegate = self
        createSpinner.isHidden = true
        
        startListeningForKeyboardChanges()
    }
    
    override func willMove(toParent parent: UIViewController?) {
        if parent == nil {
            stopListeningForKeyboardChanges()
        }
    }
    
    @IBAction func createChat(_ sender: Any) {
        if let error = viewModel.validationError() {
            highlightErroredFields(error: error)
            return
        }
        
        createButton.isHidden = true
        createSpinner.isHidden = false
        createSpinner.startAnimating()
        viewModel.createChat()
    }
    
    @IBAction func goBack(_ sender: Any) {
        delegate?.newChatViewControllerDidSelectBack(self)
    }
    
    private func listenForChanges() {
        viewModel.didChange = { change in
            DispatchQueue.main.async {
                switch change {
                case .loaded:
                    self.toggleEmptyView()
                    self.collectionView.reloadData()
                case let .chatCreated(chat):
                    self.delegate?.newChatViewController(self, didCreateChat: chat)
                }
            }
        }

        viewModel.listenForData()
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
            ContactCell.nib,
            forCellWithReuseIdentifier: "cell"
        )
        
        collectionView.allowsMultipleSelection = true
        collectionView.delegate = self
        collectionView.dataSource = self
    }
}

extension NewChatViewController: UITextFieldDelegate {
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
        
        viewModel.setTitle(newString)        
        return true
    }
}

extension NewChatViewController: UICollectionViewDataSource, UICollectionViewDelegate {
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
        viewModel.selectContact(contact: item.contact)
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let item = viewModel.items[indexPath.row]
        viewModel.selectContact(contact: item.contact)
    }
}

extension NewChatViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        CGSize(width: collectionView.frame.width, height: 80.0)
    }
}

extension NewChatViewController {
    func startListeningForKeyboardChanges() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(
            self,
            selector: #selector(adjustForKeyboard),
            name: UIResponder.keyboardWillHideNotification, object: nil
        )
        
        notificationCenter.addObserver(
            self,
            selector: #selector(adjustForKeyboard),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
    }
    
    func stopListeningForKeyboardChanges() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.removeObserver(self)
    }
    
    @objc func adjustForKeyboard(notification: Notification) {
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }

        let keyboardScreenEndFrame = keyboardValue.cgRectValue
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)

        if notification.name == UIResponder.keyboardWillHideNotification {
            keyboardBottomConstraints.forEach {
                $0.constant = 0.0
            }
        } else {
            keyboardBottomConstraints.forEach {
                $0.constant = keyboardViewEndFrame.height
            }
        }
        
        UIView.animate(withDuration: 0.3) {
            self.view.setNeedsLayout()
        }
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}
