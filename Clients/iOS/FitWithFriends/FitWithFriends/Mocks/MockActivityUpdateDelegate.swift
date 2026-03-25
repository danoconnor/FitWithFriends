//
//  MockActivityUpdateDelegate.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 3/26/24.
//

import Foundation

public class MockActivityUpdateDelegate: ActivityUpdateDelegate {
    public var activityDataUpdatedCallCount = 0

    public init() {}

    public func activityDataUpdated() {
        activityDataUpdatedCallCount += 1
        // Mock implementation
        print("Mock activity data updated")
    }
}
