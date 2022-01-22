//
//  EmailUtility.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 1/10/21.
//

import Foundation
import MessageUI

class EmailUtility: NSObject, MFMailComposeViewControllerDelegate {
    private var emailViewController: MFMailComposeViewController?

    func sendEmailWithTextAttachement(subject: String, body: String, to: String, attachmentText: String, attachementFileName: String){
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

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        emailViewController?.dismiss(animated: true) { [weak self] in
            self?.emailViewController = nil
        }
    }

    func getRootViewController() -> UIViewController? {
        return UIApplication.shared.windows.first?.rootViewController
    }
}
