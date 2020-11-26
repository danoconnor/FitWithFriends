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
        // logMessage.file will contain the full path to the file, so parse it to just get the filename
        var file = "<file>"
        if let lastFilePart = logMessage.file.split(separator: "/").last {
            file = String(lastFilePart)
        }

        return String(format: "%@ | %@ | %@ | %@:%@ | %@",
                      dateFormatter.string(from: logMessage.timestamp),
                      logMessage.flag.description,
                      logMessage.threadID,
                      file,
                      logMessage.line.description,
                      logMessage.message)
    }
}
