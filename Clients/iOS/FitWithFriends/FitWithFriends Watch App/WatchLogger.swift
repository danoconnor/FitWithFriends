//
//  WatchLogger.swift
//  FitWithFriends Watch App
//
//  Minimal Logger replacement for the Watch target. Shared code calls Logger.traceInfo(...) etc.
//  On iOS those route through CocoaLumberjack; on watchOS we use os.Logger to avoid pulling
//  in the CocoaLumberjack SPM dependency (which has cross-platform module-map issues with xcodebuild).
//

import Foundation
import os

class Logger {
    private static let osLog = os.Logger(subsystem: "com.danoconnor.FitWithFriends.watchkitapp", category: "FWF")

    static func setupLogging() {}
    static func flushLog() {}
    static func getFileLogs() -> String { "" }

    static func traceError(message: String, error: Error? = nil, file: String = #file, functionName: String = #function, line: UInt = #line) {
        if let error = error {
            osLog.error("\(message, privacy: .public) Error: \(error.localizedDescription, privacy: .public)")
        } else {
            osLog.error("\(message, privacy: .public)")
        }
    }

    static func traceWarning(message: String, file: String = #file, functionName: String = #function, line: UInt = #line) {
        osLog.warning("\(message, privacy: .public)")
    }

    static func traceInfo(message: String, file: String = #file, functionName: String = #function, line: UInt = #line) {
        osLog.info("\(message, privacy: .public)")
    }

    static func traceVerbose(message: String, file: String = #file, functionName: String = #function, line: UInt = #line) {
        osLog.debug("\(message, privacy: .public)")
    }
}
