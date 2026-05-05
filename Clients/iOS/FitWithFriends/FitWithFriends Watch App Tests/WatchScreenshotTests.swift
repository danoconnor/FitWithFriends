//
//  WatchScreenshotTests.swift
//  FitWithFriends Watch App Tests
//
//  Renders the Watch SwiftUI surface to PNGs at App Store Connect watch dimensions.
//  This is the watchOS equivalent of the iOS `ScreenshotTests.swift` — fastlane's
//  snapshot/XCUITest does not support watchOS, so we instead snapshot SwiftUI views
//  directly using pointfreeco/swift-snapshot-testing and ship the PNGs via a custom
//  fastlane lane.
//

import SwiftUI
import XCTest
import SnapshotTesting
@testable import Fit_with_Friends

final class WatchScreenshotTests: XCTestCase {
    private struct WatchDevice {
        let name: String
        let width: CGFloat
        let height: CGFloat
    }

    /// Dimensions matching Apple Watch Connect's accepted screenshot sizes.
    /// Ultra 2 49mm doubles as the "catch-all" size — it's the largest and is
    /// accepted for every watch device class via App Store Connect scaling.
    private let watchDevices: [WatchDevice] = [
        WatchDevice(name: "APP_WATCH_ULTRA",     width: 410, height: 502),
        WatchDevice(name: "APP_WATCH_SERIES_10", width: 396, height: 484),
        WatchDevice(name: "APP_WATCH_SERIES_7",  width: 352, height: 430)
    ]

    private var recordMode: Bool {
        ProcessInfo.processInfo.environment["SNAPSHOT_RECORD_MODE"] == "1"
    }

    // MARK: - Fixtures

    private func seedCompetition(name: String,
                                 start: Date,
                                 end: Date,
                                 results: [UserCompetitionPoints]) -> CompetitionOverview {
        CompetitionOverview(name: name, start: start, end: end, currentResults: results)
    }

    private func twoActiveCompetitions(currentUserInSecondPlace: Bool) -> [CompetitionOverview] {
        let now = Date()
        let inThreeDays = now.addingTimeInterval(86_400 * 3)
        let inFiveDays = now.addingTimeInterval(86_400 * 5)
        let yesterday = now.addingTimeInterval(-86_400)

        let mainResults: [UserCompetitionPoints] = currentUserInSecondPlace ? [
            UserCompetitionPoints(userId: "u_alice", firstName: "Alice", lastName: "A", total: 425, today: 55),
            UserCompetitionPoints(userId: "u_me",    firstName: "You",   lastName: "",  total: 325, today: 25),
            UserCompetitionPoints(userId: "u_bob",   firstName: "Bob",   lastName: "B", total: 300, today: 45),
            UserCompetitionPoints(userId: "u_carol", firstName: "Carol", lastName: "C", total: 240, today: 10),
            UserCompetitionPoints(userId: "u_dave",  firstName: "Dave",  lastName: "D", total: 180, today: 0),
            UserCompetitionPoints(userId: "u_eve",   firstName: "Eve",   lastName: "E", total: 120, today: 0)
        ] : [
            UserCompetitionPoints(userId: "u_me",    firstName: "You",   lastName: "",  total: 500, today: 70),
            UserCompetitionPoints(userId: "u_alice", firstName: "Alice", lastName: "A", total: 420, today: 40),
            UserCompetitionPoints(userId: "u_bob",   firstName: "Bob",   lastName: "B", total: 300, today: 20)
        ]

        let secondaryResults: [UserCompetitionPoints] = [
            UserCompetitionPoints(userId: "u_me",  firstName: "You",   lastName: "",  total: 210, today: 30),
            UserCompetitionPoints(userId: "u_xx",  firstName: "Chris", lastName: "K", total: 260, today: 15),
            UserCompetitionPoints(userId: "u_yy",  firstName: "Diana", lastName: "R", total: 150, today: 10)
        ]

        return [
            seedCompetition(name: "Spring Showdown", start: yesterday, end: inThreeDays, results: mainResults),
            seedCompetition(name: "Step Sprint",      start: yesterday, end: inFiveDays,  results: secondaryResults)
        ]
    }

    private func snapshot<V: View>(_ view: V,
                                   named name: String,
                                   file: StaticString = #filePath,
                                   testName: String = #function,
                                   line: UInt = #line) {
        for device in watchDevices {
            let wrapped = view.frame(width: device.width, height: device.height)
            assertSnapshot(
                of: wrapped,
                as: .image(layout: .fixed(width: device.width, height: device.height)),
                named: "\(name)_\(device.name)",
                record: recordMode,
                file: file,
                testName: testName,
                line: line
            )
        }
    }

    // MARK: - Scenarios

    func test01_CompetitionsPager_Active() {
        let overviews = twoActiveCompetitions(currentUserInSecondPlace: true)
        let view = CompetitionsPagerView(
            overviews: overviews,
            currentUserId: "u_me",
            onRefresh: {}
        )
        snapshot(view, named: "01_CompetitionsPager_Active")
    }

    func test02_CompetitionsPager_Winning() {
        let overviews = twoActiveCompetitions(currentUserInSecondPlace: false)
        let view = CompetitionsPagerView(
            overviews: overviews,
            currentUserId: "u_me",
            onRefresh: {}
        )
        snapshot(view, named: "02_CompetitionsPager_Winning")
    }

    func test03_CompetitionDetail_FullLeaderboard() {
        let overviews = twoActiveCompetitions(currentUserInSecondPlace: true)
        let viewModel = WatchCompetitionDetailViewModel(
            competition: overviews[0],
            currentUserId: "u_me"
        )
        let view = WatchCompetitionDetailView(viewModel: viewModel)
        snapshot(view, named: "03_CompetitionDetail_FullLeaderboard")
    }

    func test04_EmptyState_SignedOut() {
        snapshot(SignedOutView(), named: "04_EmptyState_SignedOut")
    }

    func test05_EmptyState_NoCompetitions() {
        snapshot(NoCompetitionsView(), named: "05_EmptyState_NoCompetitions")
    }
}
