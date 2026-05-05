//
//  PhoneWatchSessionManager.swift
//  FitWithFriends
//
//  Manages the WatchConnectivity session on the iPhone side.
//  Sends auth tokens to the paired Apple Watch via updateApplicationContext,
//  which persists the latest state and delivers it whenever the Watch becomes reachable.
//

#if !os(watchOS)
import Foundation
import WatchConnectivity

class PhoneWatchSessionManager: NSObject, WCSessionDelegate {
    private let tokenManager: ITokenManager

    init(tokenManager: ITokenManager) {
        self.tokenManager = tokenManager
        super.init()

        guard WCSession.isSupported() else {
            Logger.traceInfo(message: "WCSession not supported on this device")
            return
        }

        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    // MARK: - Public API

    /// Send the current token to the Watch. Called after login or token refresh.
    func sendToken(_ token: Token) {
        guard WCSession.isSupported() else { return }

        do {
            let data = try JSONEncoder.fwfDefaultEncoder.encode(token)
            try WCSession.default.updateApplicationContext(["token": data])
            Logger.traceInfo(message: "Sent token to Watch via application context")
        } catch {
            Logger.traceError(message: "Failed to send token to Watch", error: error)
        }
    }

    /// Notify the Watch that the user logged out.
    func sendLogout() {
        guard WCSession.isSupported() else { return }

        do {
            try WCSession.default.updateApplicationContext(["logout": true])
            Logger.traceInfo(message: "Sent logout to Watch via application context")
        } catch {
            Logger.traceError(message: "Failed to send logout to Watch", error: error)
        }
    }

    // MARK: - WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            Logger.traceError(message: "WCSession activation failed", error: error)
            return
        }

        Logger.traceInfo(message: "WCSession activated with state: \(activationState.rawValue)")

        // If the user is already logged in when the session activates (e.g. Watch app
        // just installed), send the current token so the Watch has it immediately.
        if activationState == .activated, session.isPaired, session.isWatchAppInstalled {
            sendCurrentTokenIfAvailable()
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        // Re-activate for Watch switching scenarios
        WCSession.default.activate()
    }

    // MARK: - Private

    private func sendCurrentTokenIfAvailable() {
        do {
            let token = try tokenManager.getCachedToken()
            sendToken(token)
        } catch {
            // No valid token — nothing to send
        }
    }
}
#endif
