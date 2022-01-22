//
//  MockShakeGestureHandler.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 1/22/22.
//

import Foundation

class MockShakeGestureHandler: ShakeGestureHandler {
    init() {
        super.init(emailUtility: MockEmailUtility())
    }

    override func handleShakeGesture() {}
}
