//
//  UIWindow+Extensions.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 1/10/21.
//

import Foundation
import UIKit

extension UIWindow {
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        super.motionEnded(motion, with: event)

        if motion == .motionShake {
            FitWithFriendsApp.objectGraph.shakeGestureHandler.handleShakeGesture()
        }
    }
}
