//
//  JoinCompetitionProtocolData.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 2/20/22.
//

import Foundation

/// The data when the app is launched with a protocol to join a competition
public class JoinCompetitionProtocolData: AppProtocolData {
    public static let action = AppProtocolAction.joinCompetition

    private static let competitionTokenKey = "competitiontoken"
    private static let competitionIdKey = "competitionid"

    public let competitionId: UUID
    public let competitionToken: String

    /// Expected url: fitwithfriends://joincompetition?competitionToken=COMPETITIONTOKEN&competitionId=10
    public init?(urlComponents: URLComponents) {
        guard let queryItems = urlComponents.queryItems else {
            return nil
        }

        var id: UUID?
        var token: String?
        for queryItem in queryItems {
            switch queryItem.name.lowercased() {
            case JoinCompetitionProtocolData.competitionIdKey:
                id = UUID(uuidString: queryItem.value ?? "")
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
    public static func createAppProtocolUrl(competitionId: UUID, competitionToken: String) -> URL {
        let url = "\(SecretConstants.baseAppProtocol)://\(action.rawValue)?\(JoinCompetitionProtocolData.competitionTokenKey)=\(competitionToken)&\(JoinCompetitionProtocolData.competitionIdKey)=\(competitionId.description)"
        return URL(string: url)!
    }

    /// Expected url: https://<service base>/joincompetition?competitionToken=COMPETITIONTOKEN&competitionId=10
    /// Associated domains should cause this website URL to open in the app, if the app is installed on the device
    /// If the app is not installed, then the webpage will load and prompt the user to download the app from the App Store
    public static func createWebsiteUrl(competitionId: UUID, competitionToken: String) -> URL {
        let url = "\(SecretConstants.serviceBaseUrl)/\(action.rawValue)?\(JoinCompetitionProtocolData.competitionTokenKey)=\(competitionToken)&\(JoinCompetitionProtocolData.competitionIdKey)=\(competitionId.description)"
        return URL(string: url)!
    }
}
