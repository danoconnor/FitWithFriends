//
//  MockShakeGestureHandler.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 1/22/22.
//

import Foundation

public class MockShakeGestureHandler: IShakeGestureHandler {
    public init() {}

    public var return_handleShakeGesture_error: Error?
    public var handleShakeGestureCallCount = 0

    public func handleShakeGesture() {
        handleShakeGestureCallCount += 1
        if return_handleShakeGesture_error != nil {
            // Handle mock error
        }
    }
}
