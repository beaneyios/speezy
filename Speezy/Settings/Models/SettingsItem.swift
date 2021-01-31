//
//  SettingsItem.swift
//  Speezy
//
//  Created by Matt Beaney on 02/08/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import Foundation
import UIKit

struct SettingsItem {
    enum Identifier {
        case acknowledgements
        case feedback
        case privacyPolicy
        case logout
    }
    
    var icon: UIImage?
    var title: String
    var identifier: Identifier
}
