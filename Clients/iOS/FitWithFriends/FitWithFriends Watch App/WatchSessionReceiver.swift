//
//  WatchSessionReceiver.swift
//  FitWithFriends Watch App
//
//  Receives auth tokens from the paired iPhone via WatchConnectivity.
//  Stores them in the Watch's local Keychain and updates the authentication state.
//

import Foundation
import WatchConnectivity

class WatchSessionReceiver: NSObject, WCSessionDelegate {
    private let tokenManager: ITokenManager
    private let authenticationManager: WatchAuthenticationManager

    init(tokenManager: ITokenManager, authenticationManager: WatchAuthenticationManager) {
        self.tokenManager = tokenManager
        self.authenticationManager = authenticationManager
        super.init()

        guard WCSession.isSupported() else {
            Logger.traceInfo(message: "WCSession not supported")
            return
        }

        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    // MARK: - WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            Logger.traceError(message: "Watch WCSession activation failed", error: error)
            return
        }

        Logger.traceInfo(message: "Watch WCSession activated with state: \(activationState.rawValue)")

        // Check if there's a pending application context delivered while we were inactive
        let context = session.receivedApplicationContext
        if !context.isEmpty {
            handleApplicationContext(context)
        }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        handleApplicationContext(applicationContext)
    }

    #if !os(watchOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {}
    #endif

    // MARK: - Private

    private func handleApplicationContext(_ context: [String: Any]) {
        if context["logout"] as? Bool == true {
            Logger.traceInfo(message: "Received logout from iPhone")
            DispatchQueue.main.async {
                self.authenticationManager.logout()
            }
            return
        }

        guard let tokenData = context["token"] as? Data else { return }

        do {
            let token = try JSONDecoder.fwfDefaultDecoder.decode(Token.self, from: tokenData)
            tokenManager.storeToken(token)
            Logger.traceInfo(message: "Received and stored token from iPhone for user: \(token.userId)")

            DispatchQueue.main.async {
                self.authenticationManager.handleReceivedToken(token)
            }
        } catch {
            Logger.traceError(message: "Failed to decode token from iPhone", error: error)
        }
    }
}
