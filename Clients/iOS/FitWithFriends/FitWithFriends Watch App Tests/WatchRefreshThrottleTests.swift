//
//  WatchRefreshThrottleTests.swift
//  FitWithFriends Watch App Tests
//
//  Created by Dan O'Connor on 4/14/26.
//

import XCTest
@testable import FitWithFriends_Watch_App

final class WatchRefreshThrottleTests: XCTestCase {
    private var now: Date = Date(timeIntervalSince1970: 1_000_000)
    private var throttle: WatchRefreshThrottle!

    override func setUp() {
        super.setUp()
        now = Date(timeIntervalSince1970: 1_000_000)
        throttle = WatchRefreshThrottle(minimumInterval: 60, clock: { [unowned self] in self.now })
    }

    override func tearDown() {
        throttle = nil
        super.tearDown()
    }

    func test_firstCall_alwaysRefreshes() {
        XCTAssertTrue(throttle.shouldRefresh())
    }

    func test_secondCall_withinInterval_isNoOp() {
        _ = throttle.shouldRefresh()
        now = now.addingTimeInterval(30)
        XCTAssertFalse(throttle.shouldRefresh(), "Second call within 60s must be throttled")
    }

    func test_secondCall_atExactlyInterval_refreshes() {
        _ = throttle.shouldRefresh()
        now = now.addingTimeInterval(60)
        XCTAssertTrue(throttle.shouldRefresh(), "Call at exactly the 60s boundary should refresh")
    }

    func test_secondCall_afterInterval_refreshes() {
        _ = throttle.shouldRefresh()
        now = now.addingTimeInterval(120)
        XCTAssertTrue(throttle.shouldRefresh())
    }

    func test_invalidate_forcesRefresh() {
        _ = throttle.shouldRefresh()
        now = now.addingTimeInterval(10)
        throttle.invalidate()
        XCTAssertTrue(throttle.shouldRefresh(), "invalidate() must bypass the throttle")
    }

    func test_repeatedRefresh_updatesBaselineEachTime() {
        _ = throttle.shouldRefresh()          // t=0
        now = now.addingTimeInterval(70)
        _ = throttle.shouldRefresh()          // t=70, allowed
        now = now.addingTimeInterval(30)
        XCTAssertFalse(throttle.shouldRefresh(), "t=100 is within 60s of the t=70 refresh")
        now = now.addingTimeInterval(40)
        XCTAssertTrue(throttle.shouldRefresh(), "t=140 is >60s past the last refresh")
    }
}
