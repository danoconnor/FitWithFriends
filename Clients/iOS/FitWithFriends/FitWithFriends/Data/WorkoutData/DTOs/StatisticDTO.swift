//
//  StatisticDTO.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 4/6/24.
//

import Foundation
import HealthKit

/// Translates from the HealthKit HKStatistics class
public struct StatisticDTO {
    public let sumValue: UInt

    public init(hkStatistic: HKStatistics, unit: HKUnit) {
        guard let quantity = hkStatistic.sumQuantity() else {
            Logger.traceError(message: "Could not get statistic sum quantity")
            sumValue = 0
            return
        }

        sumValue = UInt(round(quantity.doubleValue(for: unit)))
    }

    /// Initializer for unit tests, not used in production code
    public init(sumValue: UInt) {
        self.sumValue = sumValue
    }
}
