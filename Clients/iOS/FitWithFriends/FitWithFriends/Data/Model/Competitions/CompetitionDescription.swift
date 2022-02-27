//
//  CompetitionDescription.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 2/21/22.
//

import Foundation

/// This description contains details about the competition and is provided when a user clicks a join competition link, but has not yet joined the competition
class CompetitionDescription: Codable {
    let adminName: String
    let competitionName: String
    let competitionStart: Date
    let competitionEnd: Date
    let numMembers: UInt

    /// This init is used for testing and mock data. Production code will decode the entity from JSON
    init(adminName: String = "Admin Name", competitionName: String = "Test Competition", start: Date = Date(), end: Date = Date(), numMembers: UInt = 0) {
        self.adminName = adminName
        self.competitionName = competitionName
        competitionStart = start
        competitionEnd = end
        self.numMembers = numMembers
    }
}
