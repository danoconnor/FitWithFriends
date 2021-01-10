//
//  EmailUtility.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 1/10/21.
//

import Foundation
import MessageUI

class EmailUtility: NSObject, MFMailComposeViewControllerDelegate {
    private var isShowingEmailView = false

    func sendEmailWithTextAttachement(subject: String, body: String, to: String, attachmentText: String, attachementFileName: String){
        guard MFMailComposeViewController.canSendMail() else {
            Logger.traceWarning(message: "Cannot send email")
            return
        }

        let picker = MFMailComposeViewController()

        picker.setSubject(subject)
        picker.setMessageBody(body, isHTML: true)
        picker.setToRecipients([to])
        picker.mailComposeDelegate = self
        picker.addAttachmentData(attachmentText.data(using: .utf8)!, mimeType: "text", fileName: attachementFileName)

        DispatchQueue.main.async { [weak self] in
            guard self?.isShowingEmailView == false else {
                Logger.traceWarning(message: "Already presenting email view")
                return
            }

            self?.isShowingEmailView = true
            self?.getRootViewController()?.present(picker, animated: true, completion: nil)
        }
    }

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        getRootViewController()?.dismiss(animated: true) { [weak self] in
            self?.isShowingEmailView = false
        }
    }

    func getRootViewController() -> UIViewController? {
        return UIApplication.shared.windows.first?.rootViewController
    }
}
