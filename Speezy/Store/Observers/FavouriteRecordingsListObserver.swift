//
//  FavouriteRecordingsListObser.swift
//  Speezy
//
//  Created by Matt Beaney on 07/02/2021.
//  Copyright © 2021 Speezy. All rights reserved.
//

import Foundation

protocol FavouriteRecordingsListObserver: AnyObject {
    func favouriteAdded(favourite: AudioItem, favourites: [AudioItem])
    func favouriteUpdated(favourite: AudioItem, favourites: [AudioItem])
    func pagedFavouritesReceived(favourites: [AudioItem])
    func favouriteRemoved(favourite: AudioItem, favourites: [AudioItem])
}
