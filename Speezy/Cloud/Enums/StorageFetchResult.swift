//
//  StorageFetchResult.swift
//  Speezy
//
//  Created by Matt Beaney on 24/01/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation

enum StorageFetchResult<T> {
    case success(T)
    case failure(Error?)
}
