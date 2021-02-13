//
//  ProfileObserver.swift
//  Speezy
//
//  Created by Matt Beaney on 13/02/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation

protocol ProfileObserver: AnyObject {
    func initialProfileReceived(profile: Profile)
    func profileUpdated(profile: Profile)
}
