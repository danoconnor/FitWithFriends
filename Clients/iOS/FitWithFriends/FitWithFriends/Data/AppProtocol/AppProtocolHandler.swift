//
//  AppProtocolHandler.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 2/20/22.
//

import Combine
import Foundation

enum AppProtocolAction: String {
    case joinCompetition = "joincompetition"
}

protocol AppProtocolData {
    static var action: AppProtocolAction { get }
}

class AppProtocolHandler: ObservableObject {
    @Published private(set) var protocolData: AppProtocolData?

    /// Takes the appropriate actions to handle the given protocol
    /// Returns true if the protocol was handled, false otherwise
    func handleProtocol(url: URL) -> Bool {
        guard let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let host = urlComponents.host?.lowercased() else {
            return false
        }

        var newProtocolData: AppProtocolData?
        switch host {
        case AppProtocolAction.joinCompetition.rawValue:
            newProtocolData = JoinCompetitionProtocolData(urlComponents: urlComponents)
        default:
            Logger.traceWarning(message: "Could not handle protocol: \(url.absoluteString)")
        }

        DispatchQueue.main.async {
            self.protocolData = newProtocolData
        }

        return newProtocolData != nil
    }

    func clearProtocolData() {
        Logger.traceInfo(message: "Clearing protocol data")
        protocolData = nil
    }
}
