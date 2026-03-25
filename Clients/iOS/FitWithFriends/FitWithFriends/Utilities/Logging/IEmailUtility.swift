import Foundation

/**
 A protocol defining the interface for sending emails.
 */
protocol IEmailUtility: AnyObject {
    /// Sends a log email with the application's log file attached.
    func sendLogEmail()

    /// Sends an email with a text attachment.
    /// - Parameters:
    ///   - subject: The subject of the email.
    ///   - body: The body of the email.
    ///   - to: The recipient's email address.
    ///   - attachmentText: The text content of the attachment.
    ///   - attachementFileName: The name of the attachment file.
    func sendEmailWithTextAttachement(subject: String, body: String, to: String, attachmentText: String, attachementFileName: String)
}
