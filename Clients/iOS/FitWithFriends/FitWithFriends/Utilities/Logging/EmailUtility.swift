//
//  EmailUtility.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 1/10/21.
//

import Foundation
import MessageUI

public class EmailUtility: NSObject, MFMailComposeViewControllerDelegate {
    private var emailViewController: MFMailComposeViewController?

    public func sendLogEmail() {
        Logger.traceInfo(message: "Sending log email")
        Logger.flushLog()

        let logs = Logger.getFileLogs()
        sendEmailWithTextAttachement(subject: "FitWithFriends log file",
                                     body: "Log file is attached",
                                     to: SecretConstants.supportEmail,
                                     attachmentText: logs,
                                     attachementFileName: "FitWithFriends_Logs.txt")
    }

    public func sendEmailWithTextAttachement(subject: String, body: String, to: String, attachmentText: String, attachementFileName: String){
        guard MFMailComposeViewController.canSendMail() else {
            Logger.traceWarning(message: "Cannot send email")
            return
        }

        guard emailViewController == nil else {
            Logger.traceWarning(message: "Already presenting email view")
            return
        }

        let mailController = MFMailComposeViewController()
        emailViewController = mailController

        mailController.setSubject(subject)
        mailController.setMessageBody(body, isHTML: true)
        mailController.setToRecipients([to])
        mailController.mailComposeDelegate = self
        mailController.addAttachmentData(attachmentText.data(using: .utf8)!, mimeType: "text", fileName: attachementFileName)

        DispatchQueue.main.async { [weak self] in
            self?.getRootViewController()?.present(mailController, animated: true, completion: nil)
        }
    }

    public func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        emailViewController?.dismiss(animated: true) { [weak self] in
            self?.emailViewController = nil
        }
    }

    private func getRootViewController() -> UIViewController? {
        guard let rootViewController = UIApplication.shared.activeKeyWindow?.rootViewController else {
            Logger.traceWarning(message: "Couldn't find root view controller")
            return nil
        }

        // Try to find the view controller that is on top right now
        return rootViewController.presentedViewController ?? rootViewController
    }
}
