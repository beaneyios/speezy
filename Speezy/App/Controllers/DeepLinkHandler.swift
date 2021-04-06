//
//  DeepLinkHandler.swift
//  Speezy
//
//  Created by Matt Beaney on 06/04/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation
import FirebaseDynamicLinks

struct DeepLinkHandler {
    static func contactId(for url: URL) -> String? {
        if let contactId = url.queryParameters?["contact_id"] {
            return contactId
        } else if
            let dynamicLinkURL = DynamicLinks.dynamicLinks().dynamicLink(fromUniversalLink: url)?.url,
            let contactId = dynamicLinkURL.queryParameters?["contact_id"]
        {
            return contactId
        } else {
            return nil
        }
    }
}
