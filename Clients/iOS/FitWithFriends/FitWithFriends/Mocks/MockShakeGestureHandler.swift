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

    public func handleShakeGesture() {
        if let error = return_handleShakeGesture_error {
            // Handle mock error
        }
    }
}
