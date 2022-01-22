//
//  MockEmailUtility.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 1/22/22.
//

import Foundation

class MockEmailUtility: EmailUtility {
    override func sendEmailWithTextAttachement(subject: String, body: String, to: String, attachmentText: String, attachementFileName: String) {}
}
