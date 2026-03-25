//
//  MockActivityUpdateDelegate.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 3/26/24.
//

import Foundation

public class MockActivityUpdateDelegate: ActivityUpdateDelegate {
    public init() {}

    public func activityDataUpdated() {
        // Mock implementation
        print("Mock activity data updated")
    }
}
