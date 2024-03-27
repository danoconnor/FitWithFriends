//
//  MockActivityUpdateDelegate.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 3/26/24.
//

import Foundation

public class MockActivityUpdateDelegate: ActivityUpdateDelegate {
    public var updateCalled = false
    public func activityDataUpdated() {
        updateCalled = true
    }

    public init() {}
}
