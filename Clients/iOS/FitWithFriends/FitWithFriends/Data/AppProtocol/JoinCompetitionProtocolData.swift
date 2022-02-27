//
//  JoinCompetitionProtocolData.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 2/20/22.
//

import Foundation

/// The data when the app is launched with a protocol to join a competition
class JoinCompetitionProtocolData: AppProtocolData {
    static let action = AppProtocolAction.joinCompetition

    private static let competitionTokenKey = "competitiontoken"
    private static let competitionIdKey = "competitionid"

    let competitionId: UInt
    let competitionToken: String

    /// Expected url: fitwithfriends://joincompetition?competitionToken=COMPETITIONTOKEN&competitionId=10
    init?(urlComponents: URLComponents) {
        guard let queryItems = urlComponents.queryItems else {
            return nil
        }

        var id: UInt?
        var token: String?
        for queryItem in queryItems {
            switch queryItem.name.lowercased() {
            case JoinCompetitionProtocolData.competitionIdKey:
                id = UInt(queryItem.value ?? "")
            case JoinCompetitionProtocolData.competitionTokenKey:
                token = queryItem.value
            default:
                continue
            }
        }

        guard let id = id, let token = token else {
            return nil
        }

        competitionId = id
        competitionToken = token
    }

    /// Expected url: fitwithfriends://joincompetition?competitionToken=COMPETITIONTOKEN&competitionId=10
    static func createUrl(competitionId: UInt, competitionToken: String) -> URL {
        let url = "\(SecretConstants.baseAppProtocol)://\(action.rawValue)?\(JoinCompetitionProtocolData.competitionTokenKey)=\(competitionToken)&\(JoinCompetitionProtocolData.competitionIdKey)=\(competitionId.description)"
        return URL(string: url)!
    }
}
