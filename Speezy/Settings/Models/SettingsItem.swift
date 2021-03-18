//
//  SettingsItem.swift
//  Speezy
//
//  Created by Matt Beaney on 02/08/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import Foundation
import UIKit

enum SettingsItem: CaseIterable {
    case acknowledgements
    case feedback
    case privacyPolicy
    case shareApp
    case logout
    case deleteAccount
    
    var icon: UIImage? {
        switch self {
        case .acknowledgements:
            return UIImage(named: "heart-icon")
        case .feedback:
            return UIImage(named: "feedback-icon")
        case .privacyPolicy:
            return UIImage(named: "tos-icon")
        case .shareApp:
            return UIImage(named: "settings-share-button")
        case .logout:
            return UIImage(named: "account-btn")
        case .deleteAccount:
            return UIImage(named: "delete-account")
        }
    }
    
    var title: String {
        switch self {
        case .acknowledgements:
            return "Acknowledgements"
        case .feedback:
            return "Feedback"
        case .privacyPolicy:
            return "Privacy Policy"
        case .shareApp:
            return "Share app"
        case .logout:
            return "Log out"
        case .deleteAccount:
            return "Delete your account"
        }
    }
}
