//
//  ShakeGestureHandler.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 1/10/21.
//

import Foundation
import UIKit

class ShakeGestureHandler {
    private let emailUtility: EmailUtility

    init(emailUtility: EmailUtility) {
        self.emailUtility = emailUtility
    }

    func handleShakeGesture() {
        Logger.traceInfo(message: "Shake gesture detected")

        // TODO: Add menu with more options
        sendLogEmail()
    }

    private func sendLogEmail() {
        let logs = Logger.getFileLogs()
        emailUtility.sendEmailWithTextAttachement(subject: "FitWithFriends log file",
                                                  body: "Log file is attached",
                                                  to: SecretConstants.supportEmail,
                                                  attachmentText: logs,
                                                  attachementFileName: "FitWithFriends_Logs.txt")
    }
}
