//
//  WatchRefreshThrottle.swift
//  FitWithFriends Watch App
//
//  Created by Dan O'Connor on 4/14/26.
//

import Foundation

/// Prevents over-eager refresh calls when the user rapidly glances at the Watch.
/// The first call always fetches; subsequent calls within `minimumInterval` are
/// no-ops. Uses a caller-provided clock so tests can advance time without waiting.
final class WatchRefreshThrottle {
    typealias Clock = () -> Date

    private let minimumInterval: TimeInterval
    private let clock: Clock
    private var lastRefresh: Date?

    init(minimumInterval: TimeInterval = 60, clock: @escaping Clock = { Date() }) {
        self.minimumInterval = minimumInterval
        self.clock = clock
    }

    /// Returns true if a refresh should run, marking this moment as the latest refresh.
    func shouldRefresh() -> Bool {
        let now = clock()
        if let last = lastRefresh, now.timeIntervalSince(last) < minimumInterval {
            return false
        }
        lastRefresh = now
        return true
    }

    /// Forces the next `shouldRefresh()` call to return true. Useful for pull-to-refresh.
    func invalidate() {
        lastRefresh = nil
    }
}
