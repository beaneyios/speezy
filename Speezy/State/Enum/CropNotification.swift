//
//  CropNotification.swift
//  Speezy
//
//  Created by Matt Beaney on 14/11/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import UIKit

enum CropAction {
    case showCrop(AudioItem, CropKind)
    case showCropAdjusted(AudioItem)
    case showCropCancelled(AudioItem)
    case showCropFinished(AudioItem)
    case leftHandleMoved(percentage: CGFloat)
    case rightHandleMoved(percentage: CGFloat)
}
