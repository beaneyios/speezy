//
//  SettingsListViewController.swift
//  Speezy
//
//  Created by Matt Beaney on 02/08/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import Foundation
import UIKit
import SnapKit
import MessageUI
import DeviceKit

protocol SettingsItemListViewControllerDelegate: AnyObject {
    func settingsItemListViewController(_ viewController: SettingsItemListViewController, didSelectSettingsItem item: SettingsItem)
}

class SettingsItemListViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
        
    weak var delegate: SettingsItemListViewControllerDelegate?
    var settingsItems: [SettingsItem] = [
        SettingsItem(icon: UIImage(named: "heart-icon"), title: "Acknowledgements", identifier: .acknowledgements),
        SettingsItem(icon: UIImage(named: "tos-icon"), title: "Privacy Policy", identifier: .privacyPolicy),
        SettingsItem(icon: UIImage(named: "feedback-icon"), title: "Feedback", identifier: .feedback)
    ]
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 91.0, right: 0)
        tableView.estimatedRowHeight = 100.0
        tableView.register(UINib(nibName: "SettingsCell", bundle: nil), forCellReuseIdentifier: "cell")
        tableView.delegate = self
        tableView.dataSource = self
        
        let footer = SettingsFooterView.createFromNib()
        let container = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 40))
        
        tableView.tableFooterView = container
        
        container.addSubview(footer)
        
        footer.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
        
        footer.configure()
    }
    
    @IBAction func didTapBack(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
}

extension SettingsItemListViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        settingsItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let settingsItem = settingsItems[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as! SettingsCell
        cell.configure(with: settingsItem)
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let settingsItem = settingsItems[indexPath.row]
        
        if settingsItem.identifier == .feedback {
            sendEmail()
            return
        }
        
        delegate?.settingsItemListViewController(self, didSelectSettingsItem: settingsItem)
    }
}

extension SettingsItemListViewController: MFMailComposeViewControllerDelegate {
    func sendEmail() {
        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            
            let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
            let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
            
            mail.mailComposeDelegate = self
            mail.setToRecipients(["james@suggestv.io"])
            mail.setMessageBody(
                """
                <h3>Speezy support request</h3>
                <p>
                    Type your feedback/request below.
                </p>
                <br><br><br><br>
                <p>
                    Device: \(Device.current) <br>
                    iOS Version: \(UIDevice.current.systemVersion) <br>
                    App Version: \(appVersion ?? "N/A") (\(buildNumber ?? "N/A"))
                </p>
                """,
                isHTML: true
            )
            present(mail, animated: true)
        } else {
            // show failure alert
        }
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
}
