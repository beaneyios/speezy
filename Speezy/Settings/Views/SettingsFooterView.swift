//
//  SettingsFooterView.swift
//  Speezy
//
//  Created by Matt Beaney on 02/08/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import Foundation
import UIKit

class SettingsFooterView: UIView, NibLoadable {
    @IBOutlet weak var lblTitle: UILabel!
    
    func configure() {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
        
        lblTitle.text = "App Version \(appVersion ?? "1.0") (\(buildNumber ?? "1"))"
    }
}
