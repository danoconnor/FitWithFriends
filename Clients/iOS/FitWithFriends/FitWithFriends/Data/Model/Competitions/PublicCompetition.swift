//
//  PublicCompetition.swift
//  FitWithFriends

import Foundation

public struct PublicCompetition: Decodable, Identifiable {
    let competitionId: UUID
    let displayName: String
    let startDate: Date
    let endDate: Date
    let memberCount: Int
    let isUserMember: Bool

    public var id: UUID { competitionId }
}

public struct PublicCompetitionsResponse: Decodable {
    let competitions: [PublicCompetition]
    let isUserPro: Bool
}
