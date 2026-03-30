//
//  SubscriptionStatus.swift
//  FitWithFriends
//

import Foundation

struct SubscriptionStatus: Decodable {
    let isPro: Bool
    let maxActiveCompetitions: Int
}
