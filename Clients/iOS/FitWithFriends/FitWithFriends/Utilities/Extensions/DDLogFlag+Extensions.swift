//
//  DDLogFlag+Extensions.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 11/21/20.
//

import CocoaLumberjack

extension DDLogFlag {
    var description: String {
        switch self {
        case .error:
            return "E"
        case .warning:
            return "W"
        case .info:
            return "I"
        case .verbose:
            return "V"
        case .debug:
            return "D"
        default:
            return "OTHER"
        }
    }
}
