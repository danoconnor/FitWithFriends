//
//  AppProtocolHandler.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 2/20/22.
//

import Combine
import Foundation

public enum AppProtocolAction: String {
    case joinCompetition = "joincompetition"
}

public protocol AppProtocolData {
    static var action: AppProtocolAction { get }
}

public class AppProtocolHandler: ObservableObject {
    @Published public private(set) var protocolData: AppProtocolData?

    /// Takes the appropriate actions to handle the given protocol
    /// Returns true if the protocol was handled, false otherwise
    public func handleProtocol(url: URL) -> Bool {
        guard let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return false
        }

        var newProtocolData: AppProtocolData?

        // First try to parse this as a normal app deeplink in the form
        // fitwithfriends://<action>?queryParams
        // In this case the URL host will be the deeplink action
        if let host = urlComponents.host {
            newProtocolData = getProtocolData(from: host, with: urlComponents)
        }

        // We were not able to parse the protocol by the host
        // This is likely an associated domains link in the form
        // https://<server base URL>/<action>?queryParams
        // In this case, the path will be the deeplink action
        if newProtocolData == nil {
            // The path will be something like "/joinCompetition", so remove the slash when parsing
            var path = urlComponents.path
            path.removeAll { $0 == "/" }

            newProtocolData = getProtocolData(from: path, with: urlComponents)
        }

        DispatchQueue.main.async {
            self.protocolData = newProtocolData
        }

        let handled = newProtocolData != nil
        if !handled {
            Logger.traceWarning(message: "Could not handle URL \(url)")
        }

        return handled
    }

    public func clearProtocolData() {
        Logger.traceInfo(message: "Clearing protocol data")
        protocolData = nil
    }

    private func getProtocolData(from action: String, with urlComponents: URLComponents) -> AppProtocolData? {
        switch action.lowercased() {
        case AppProtocolAction.joinCompetition.rawValue:
            return JoinCompetitionProtocolData(urlComponents: urlComponents)
        default:
            return nil
        }
    }
}
