//
//  TimeInterval+Extensions.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 1/18/21.
//

import Foundation

extension TimeInterval {
    /// Create a time interval instance that represents the given number of days
    static func xtDays(_ days: Double) -> TimeInterval {
        return 60 * 60 * 24 * days
    }

    /// Returns the minutes represented by the time interval instance
    var xtMinutes: Int {
        return Int(self / 60)
    }

    /// Returns the hours represented by the time interval instance
    var xtHours: Int {
        return Int(xtMinutes / 60)
    }

    /// Returns the days represented by the time interval instance
    var xtDays: Int {
        return Int(xtHours / 24)
    }
}
