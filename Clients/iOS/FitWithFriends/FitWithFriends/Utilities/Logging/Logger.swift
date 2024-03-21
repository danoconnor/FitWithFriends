//
//  Logger.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 11/21/20.
//

import CocoaLumberjackSwift
import Foundation

class Logger {
    static let logLevel = DDLogLevel.all

    static func setupLogging() {
        let logFormatter = LogFormatter()

        let logFileManager = DDLogFileManagerDefault()
        logFileManager.maximumNumberOfLogFiles = 5

        let fileLogger = DDFileLogger(logFileManager: logFileManager)
        fileLogger.logFormatter = logFormatter
        fileLogger.maximumFileSize = 1_000_000 // 1 MB
        DDLog.sharedInstance.add(fileLogger)

        #if DEBUG
            let consoleLogger = DDOSLogger.sharedInstance
            consoleLogger.logFormatter = logFormatter
            DDLog.sharedInstance.add(consoleLogger)
        #endif
    }

    static func flushLog() {
        DDLog.sharedInstance.flushLog()
    }

    static func getFileLogs() -> String {
        guard let fileLogger = DDLog.sharedInstance.allLoggers.first(where: { $0 is DDFileLogger }) as? DDFileLogger else {
            return "No file logger registered"
        }

        var logs = ""
        fileLogger.loggerQueue.sync {
            for logFilePath in fileLogger.logFileManager.sortedLogFilePaths {
                if let logFileData = FileManager.default.contents(atPath: logFilePath),
                    let logFileString = String(data: logFileData, encoding: .utf8) {
                    // The sorted file paths are given to us with the most recent first
                    // Our log file puts the oldest logs at the beginning of the file
                    logs = logFileString + logs
                }
            }
        }

        return logs
    }

    static func traceError(message: String, error: Error? = nil, file: String = #file, functionName: String = #function, line: UInt = #line) {
        var messageToLog = message
        if let error = error {
            messageToLog.append(" Error: \(error.localizedDescription) (\(error.xtDebugDescription))")
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
        let logMessage = DDLogMessage(format: message,
                                      formatted: message,
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
