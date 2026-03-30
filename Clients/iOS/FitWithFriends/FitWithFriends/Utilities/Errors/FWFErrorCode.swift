//
//  FWFErrorCode.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 11/27/22.
//

import Foundation

public enum FWFErrorCode: Int {
    case unknown = -1
    case none = 0

    // MARK: Competition errors
    
    case tooManyActiveCompetitions = 10001

    // MARK: Auth errors

    case userNotFound = 20001

    // MARK: Subscription errors

    case proSubscriptionRequired = 30001
    case invalidTransaction = 30002
}
