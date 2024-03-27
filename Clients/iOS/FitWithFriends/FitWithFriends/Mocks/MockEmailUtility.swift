//
//  MockEmailUtility.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 1/22/22.
//

import Foundation

public class MockEmailUtility: EmailUtility {
    override public func sendEmailWithTextAttachement(subject: String, body: String, to: String, attachmentText: String, attachementFileName: String) {}
}
