//
//  MockEmailUtility.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 1/22/22.
//

import Foundation

public class MockEmailUtility: IEmailUtility {
    public init() {}

    public var return_sendLogEmail_error: Error?

    public var sendLogEmailCallCount = 0
    public func sendLogEmail() {
        sendLogEmailCallCount += 1
    }

    public var param_sendEmailWithTextAttachement_subject: String?
    public var param_sendEmailWithTextAttachement_body: String?
    public var param_sendEmailWithTextAttachement_to: String?
    public var param_sendEmailWithTextAttachement_attachmentText: String?
    public var param_sendEmailWithTextAttachement_attachementFileName: String?

    public var sendEmailWithTextAttachementCallCount = 0
    public func sendEmailWithTextAttachement(subject: String, body: String, to: String, attachmentText: String, attachementFileName: String) {
        sendEmailWithTextAttachementCallCount += 1

        param_sendEmailWithTextAttachement_subject = subject
        param_sendEmailWithTextAttachement_body = body
        param_sendEmailWithTextAttachement_to = to
        param_sendEmailWithTextAttachement_attachmentText = attachmentText
        param_sendEmailWithTextAttachement_attachementFileName = attachementFileName
    }
}
