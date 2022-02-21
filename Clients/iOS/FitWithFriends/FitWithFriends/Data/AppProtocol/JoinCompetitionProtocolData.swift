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

    let competitionToken: String

    /// Expected url: fitwithfriends://joincompetition?competitionToken=COMPETITIONTOKEN
    init?(urlComponents: URLComponents) {
        guard let queryItems = urlComponents.queryItems else {
            return nil
        }

        let tokenQueryParam = queryItems.first(where: { $0.name.lowercased() == JoinCompetitionProtocolData.competitionTokenKey })
        guard let token = tokenQueryParam?.value else {
            return nil
        }

        competitionToken = token
    }

    /// Expected url: fitwithfriends://joincompetition?competitionToken=COMPETITIONTOKEN
    static func createUrl(competitionToken: String) -> URL {
        let url = "\(SecretConstants.baseAppProtocol)://\(action.rawValue)?\(JoinCompetitionProtocolData.competitionTokenKey)=\(competitionToken)"
        return URL(string: url)!
    }
}
