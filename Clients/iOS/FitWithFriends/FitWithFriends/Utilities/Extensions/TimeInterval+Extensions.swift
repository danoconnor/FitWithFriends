//
//  TimeInterval+Extensions.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 1/18/21.
//

import Foundation

extension TimeInterval {
    var xtMinutes: Int {
        return Int(self / 60)
    }

    var xtHours: Int {
        return Int(xtMinutes / 60)
    }

    var xtDays: Int {
        return Int(xtHours / 24)
    }
}
