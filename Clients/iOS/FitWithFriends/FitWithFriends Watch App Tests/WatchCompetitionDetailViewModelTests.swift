//
//  WatchCompetitionDetailViewModelTests.swift
//  FitWithFriends Watch App Tests
//
//  Created by Dan O'Connor on 4/14/26.
//

import XCTest
@testable import FitWithFriends_Watch_App

final class WatchCompetitionDetailViewModelTests: XCTestCase {
    // MARK: - leaderboardEntries

    func test_leaderboardEntries_sortsByTotalPointsDescending() {
        let competition = CompetitionOverview(
            start: Date().addingTimeInterval(-1_000),
            end: Date().addingTimeInterval(1_000),
            currentResults: [
                UserCompetitionPoints(userId: "a", firstName: "Alice", lastName: "A", total: 100, today: 0),
                UserCompetitionPoints(userId: "b", firstName: "Bob", lastName: "B", total: 300, today: 0),
                UserCompetitionPoints(userId: "c", firstName: "Carol", lastName: "C", total: 200, today: 0)
            ]
        )
        let viewModel = WatchCompetitionDetailViewModel(competition: competition, currentUserId: nil)

        let entries = viewModel.leaderboardEntries
        XCTAssertEqual(entries.map { $0.displayName }, ["Bob B", "Carol C", "Alice A"])
        XCTAssertEqual(entries.map { $0.position }, [1, 2, 3])
    }

    func test_leaderboardEntries_markTopThree() {
        let competition = CompetitionOverview(
            start: Date().addingTimeInterval(-1_000),
            end: Date().addingTimeInterval(1_000),
            currentResults: (1...5).map {
                UserCompetitionPoints(userId: "u\($0)", firstName: "U", lastName: "\($0)", total: Double(600 - $0 * 100), today: 0)
            }
        )
        let viewModel = WatchCompetitionDetailViewModel(competition: competition, currentUserId: nil)

        let entries = viewModel.leaderboardEntries
        XCTAssertEqual(entries.map { $0.isTopThree }, [true, true, true, false, false])
    }

    func test_leaderboardEntries_marksCurrentUser() {
        let competition = CompetitionOverview(
            start: Date().addingTimeInterval(-1_000),
            end: Date().addingTimeInterval(1_000),
            currentResults: [
                UserCompetitionPoints(userId: "other1", firstName: "One", lastName: "X", total: 400, today: 0),
                UserCompetitionPoints(userId: "me", firstName: "Me", lastName: "X", total: 300, today: 50),
                UserCompetitionPoints(userId: "other2", firstName: "Two", lastName: "X", total: 200, today: 0)
            ]
        )
        let viewModel = WatchCompetitionDetailViewModel(competition: competition, currentUserId: "me")

        let entries = viewModel.leaderboardEntries
        XCTAssertEqual(entries.map { $0.isCurrentUser }, [false, true, false])
        XCTAssertEqual(entries[1].pointsToday, 50)
        XCTAssertEqual(entries[1].totalPoints, 300)
    }

    func test_leaderboardEntries_withEmptyResults_returnsEmpty() {
        let competition = CompetitionOverview(currentResults: [])
        let viewModel = WatchCompetitionDetailViewModel(competition: competition, currentUserId: nil)
        XCTAssertTrue(viewModel.leaderboardEntries.isEmpty)
    }

    // MARK: - userPositionDescription

    func test_userPositionDescription_active_includesUserAndTimeRemaining() {
        let competition = CompetitionOverview(
            start: Date().addingTimeInterval(-86_400),
            end: Date().addingTimeInterval(86_400 * 3),
            currentResults: [
                UserCompetitionPoints(userId: "other", firstName: "O", lastName: "X", total: 500, today: 0),
                UserCompetitionPoints(userId: "me", firstName: "Me", lastName: "X", total: 300, today: 0),
                UserCompetitionPoints(userId: "last", firstName: "L", lastName: "X", total: 100, today: 0)
            ]
        )
        let viewModel = WatchCompetitionDetailViewModel(competition: competition, currentUserId: "me")
        let description = viewModel.userPositionDescription
        XCTAssertTrue(description.contains("You"), "Expected '\(description)' to contain 'You'")
        XCTAssertTrue(description.contains("2nd"), "Expected '\(description)' to contain '2nd'")
        XCTAssertTrue(description.contains("left"), "Expected '\(description)' to contain 'left'")
    }

    func test_userPositionDescription_notStarted_showsStarts() {
        let competition = CompetitionOverview(
            start: Date().addingTimeInterval(86_400 * 2),
            end: Date().addingTimeInterval(86_400 * 9),
            currentResults: []
        )
        let viewModel = WatchCompetitionDetailViewModel(competition: competition, currentUserId: "me")
        XCTAssertTrue(viewModel.userPositionDescription.hasPrefix("Starts "))
    }

    func test_userPositionDescription_ended_withUser_showsFinal() {
        let competition = CompetitionOverview(
            start: Date().addingTimeInterval(-86_400 * 10),
            end: Date().addingTimeInterval(-86_400),
            currentResults: [
                UserCompetitionPoints(userId: "other", firstName: "O", lastName: "X", total: 400, today: 0),
                UserCompetitionPoints(userId: "me", firstName: "Me", lastName: "X", total: 100, today: 0)
            ]
        )
        let viewModel = WatchCompetitionDetailViewModel(competition: competition, currentUserId: "me")
        let description = viewModel.userPositionDescription
        XCTAssertTrue(description.contains("Final"))
        XCTAssertTrue(description.contains("2nd"))
    }

    func test_userPositionDescription_ended_withoutUser_showsEnded() {
        let competition = CompetitionOverview(
            start: Date().addingTimeInterval(-86_400 * 10),
            end: Date().addingTimeInterval(-86_400),
            currentResults: []
        )
        let viewModel = WatchCompetitionDetailViewModel(competition: competition, currentUserId: "me")
        XCTAssertEqual(viewModel.userPositionDescription, "Ended")
    }

    // MARK: - ordinalString

    func test_ordinalString_basicCases() {
        XCTAssertEqual(WatchCompetitionDetailViewModel.ordinalString(for: 1), "1st")
        XCTAssertEqual(WatchCompetitionDetailViewModel.ordinalString(for: 2), "2nd")
        XCTAssertEqual(WatchCompetitionDetailViewModel.ordinalString(for: 3), "3rd")
        XCTAssertEqual(WatchCompetitionDetailViewModel.ordinalString(for: 4), "4th")
        XCTAssertEqual(WatchCompetitionDetailViewModel.ordinalString(for: 10), "10th")
    }

    func test_ordinalString_teensAlwaysTh() {
        XCTAssertEqual(WatchCompetitionDetailViewModel.ordinalString(for: 11), "11th")
        XCTAssertEqual(WatchCompetitionDetailViewModel.ordinalString(for: 12), "12th")
        XCTAssertEqual(WatchCompetitionDetailViewModel.ordinalString(for: 13), "13th")
    }

    func test_ordinalString_twentyOneEtc() {
        XCTAssertEqual(WatchCompetitionDetailViewModel.ordinalString(for: 21), "21st")
        XCTAssertEqual(WatchCompetitionDetailViewModel.ordinalString(for: 22), "22nd")
        XCTAssertEqual(WatchCompetitionDetailViewModel.ordinalString(for: 23), "23rd")
        XCTAssertEqual(WatchCompetitionDetailViewModel.ordinalString(for: 111), "111th")
    }

    // MARK: - relativeDateString

    func test_relativeDateString_days() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let inThreeDays = now.addingTimeInterval(86_400 * 3 + 60)
        XCTAssertEqual(WatchCompetitionDetailViewModel.relativeDateString(until: inThreeDays, now: now), "3d")
    }

    func test_relativeDateString_weeks() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let inTwoWeeks = now.addingTimeInterval(86_400 * 14 + 60)
        XCTAssertEqual(WatchCompetitionDetailViewModel.relativeDateString(until: inTwoWeeks, now: now), "2w")
    }

    func test_relativeDateString_hours() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let inFiveHours = now.addingTimeInterval(3_600 * 5)
        XCTAssertEqual(WatchCompetitionDetailViewModel.relativeDateString(until: inFiveHours, now: now), "5h")
    }

    func test_relativeDateString_pastDate_isZero() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let inThePast = now.addingTimeInterval(-3_600)
        XCTAssertEqual(WatchCompetitionDetailViewModel.relativeDateString(until: inThePast, now: now), "0d")
    }
}
