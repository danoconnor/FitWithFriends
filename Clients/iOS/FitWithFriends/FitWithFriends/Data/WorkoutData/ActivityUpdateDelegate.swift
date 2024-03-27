//
//  ActivityUpdateDelegate.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 2/18/22.
//

import Foundation

/// A delegate that is invoked whenever new activity data has been reported to the service
public protocol ActivityUpdateDelegate {
    func activityDataUpdated()
}
