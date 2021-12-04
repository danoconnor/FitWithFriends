//
//  DateFormatter+Extensions.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 1/1/21.
//

import Foundation

extension DateFormatter {
    static var isoFormatter: DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"

        return dateFormatter
    }
}
