//
//  LogFormatter.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 11/21/20.
//

import CocoaLumberjack
import Foundation

class LogFormatter: NSObject, DDLogFormatter {
    private let dateFormatter: DateFormatter

    override init() {
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
    }

    func format(message logMessage: DDLogMessage) -> String? {
        return String(format: "%@ | %@ | %@ | %@: %@ | %@",
                      dateFormatter.string(from: logMessage.timestamp),
                      logMessage.flag.description,
                      logMessage.threadID,
                      logMessage.file,
                      logMessage.line.description,
                      logMessage.message)
    }
}
