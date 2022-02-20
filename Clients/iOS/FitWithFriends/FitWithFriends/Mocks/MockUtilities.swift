//
//  MockUtilities.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 2/19/22.
//

import Foundation

class MockUtilities {
    static func delayOneSecond() async {
        try? await Task.sleep(nanoseconds: 1_000_000_000)
    }
}
