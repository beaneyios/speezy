//
//  CutNotification.swift
//  Speezy
//
//  Created by Matt Beaney on 22/11/2020.
//  Copyright © 2020 Speezy. All rights reserved.
//

import UIKit

enum CutNotification {
    case showCut(AudioItem)
    case showCutAdjusted(AudioItem)
    case showCutCancelled(AudioItem)
    case showCutFinished(AudioItem)
    case leftHandleMoved(percentage: CGFloat)
    case rightHandleMoved(percentage: CGFloat)
}
