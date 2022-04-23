//
//  ShakeGestureHandler.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 1/10/21.
//

import Foundation
import UIKit

class ShakeGestureHandler {
    private let emailUtility: EmailUtility

    init(emailUtility: EmailUtility) {
        self.emailUtility = emailUtility
    }

    func handleShakeGesture() {
        Logger.traceInfo(message: "Shake gesture detected")

        // TODO: Add menu with more options
        emailUtility.sendLogEmail()
    }
}
