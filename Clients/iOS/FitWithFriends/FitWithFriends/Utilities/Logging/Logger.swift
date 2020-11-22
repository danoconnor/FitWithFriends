//
//  Logger.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 11/21/20.
//

import CocoaLumberjack
import Foundation

class Logger {
    static let logLevel = DDLogLevel.all

    static func setupLogging() {
        let logFormatter = LogFormatter()

        let logFileManager = DDLogFileManagerDefault()
        logFileManager.maximumNumberOfLogFiles = 2

        let fileLogger = DDFileLogger()
        fileLogger.logFormatter = logFormatter
        fileLogger.maximumFileSize = 3_000_000 // 3 MB
        DDLog.sharedInstance.add(fileLogger)

        #if DEBUG
            let consoleLogger = DDOSLogger.sharedInstance
            consoleLogger.logFormatter = logFormatter
            DDLog.sharedInstance.add(consoleLogger)
        #endif
    }

    static func getFileLogs() -> String {
        var logs = ""
        let logFileManager = DDLogFileManagerDefault()

        for logFilePath in logFileManager.sortedLogFilePaths {
            if let logFileData = FileManager.default.contents(atPath: logFilePath),
                let logFileString = String(data: logFileData, encoding: .utf8) {
                // The sorted file paths are given to us with the most recent first
                // Our log file puts the oldest logs at the beginning of the file
                logs = logFileString + logs
            }
        }

        return logs
    }

    static func traceError(message: String, error: Error? = nil, file: String = #file, functionName: String = #function, line: UInt = #line) {
        var messageToLog = message
        if let error = error {
            messageToLog.append(" Error: \(error.localizedDescription)")
        }

        trace(.error, message: messageToLog, file: file, functionName: functionName, line: line)
    }

    static func traceWarning(message: String, file: String = #file, functionName: String = #function, line: UInt = #line) {
        trace(.warning, message: message, file: file, functionName: functionName, line: line)
    }

    static func traceInfo(message: String, file: String = #file, functionName: String = #function, line: UInt = #line) {
        trace(.info, message: message, file: file, functionName: functionName, line: line)
    }

    static func traceVerbose(message: String, file: String = #file, functionName: String = #function, line: UInt = #line) {
        trace(.verbose, message: message, file: file, functionName: functionName, line: line)
    }

    static func trace(_ level: DDLogFlag, message: String, file: String = #file, functionName: String = #function, line: UInt = #line) {
        let logMessage = DDLogMessage(message: message,
                                      level: logLevel,
                                      flag: level,
                                      context: 0,
                                      file: file,
                                      function: functionName,
                                      line: line,
                                      tag: nil,
                                      options: [],
                                      timestamp: Date())
        DDLog.sharedInstance.log(asynchronous: true, message: logMessage)

    }
}
