//
//  Date+Extensions.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 1/20/23.
//

import Foundation

extension Date {
    /// Converts a UTC Date object to the device's current timezone,
    /// preserving the original day/month/year/time
    ///
    /// Ex. If the Date is Jan 1 2023 00:00 UTC but the device is in EST, this func would return Jan 1 2023 00:00 EST
    func convertFromUTCToCurrentTimezone() -> Date? {
        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = .gmt

        let utcComponents = utcCalendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: self)

        // Build a date object in the current timezone based on the components
        return Calendar.current.date(from: utcComponents)
    }
}
