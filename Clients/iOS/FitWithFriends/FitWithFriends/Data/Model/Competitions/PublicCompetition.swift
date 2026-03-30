//
//  PublicCompetition.swift
//  FitWithFriends

import Foundation

struct PublicCompetition: Decodable, Identifiable {
    let competitionId: UUID
    let displayName: String
    let startDate: Date
    let endDate: Date
    let memberCount: Int
    let isUserMember: Bool

    var id: UUID { competitionId }
}

struct PublicCompetitionsResponse: Decodable {
    let competitions: [PublicCompetition]
    let isUserPro: Bool
}
