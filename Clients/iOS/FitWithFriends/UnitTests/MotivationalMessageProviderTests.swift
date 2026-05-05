//
//  MotivationalMessageProviderTests.swift
//  FitWithFriends
//

import XCTest
@testable import Fit_with_Friends

final class MotivationalMessageProviderTests: XCTestCase {

    // MARK: - Helpers

    /// Returns a Date for today at the specified hour.
    private func date(hour: Int) -> Date {
        return Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date())!
    }

    /// Returns a Date `daysOffset` days from today at the specified hour.
    private func date(hour: Int, daysOffset: Int) -> Date {
        let today = date(hour: hour)
        return Calendar.current.date(byAdding: .day, value: daysOffset, to: today)!
    }

    // MARK: - All combinations return non-empty strings

    func testAllCombinationsReturnNonEmptyString() {
        let testHours = [8, 14, 18, 22]
        let testPoints: [Double] = [0, 300, 600]

        for hour in testHours {
            for points in testPoints {
                let result = MotivationalMessageProvider.message(activityPoints: points, date: date(hour: hour))
                XCTAssertFalse(result.isEmpty, "Expected non-empty message for hour=\(hour), points=\(points)")
            }
        }
    }

    // MARK: - Activity level thresholds

    func testActivityLevelThresholds() {
        let testDate = date(hour: 8) // morning

        // 199 pts should be in the same bucket as 0 pts (low)
        let lowMessage0 = MotivationalMessageProvider.message(activityPoints: 0, date: testDate)
        let lowMessage100 = MotivationalMessageProvider.message(activityPoints: 100, date: testDate)
        let lowMessage199 = MotivationalMessageProvider.message(activityPoints: 199, date: testDate)
        let mediumPool = MotivationalMessageProvider.messages(time: .morning, level: .medium)
        let highPool = MotivationalMessageProvider.messages(time: .morning, level: .high)

        // 199 is low — should not match a medium or high message
        XCTAssertFalse(mediumPool.contains(lowMessage0), "0 pts should produce a low-level message")
        XCTAssertFalse(mediumPool.contains(lowMessage100), "100 pts should produce a low-level message")
        XCTAssertFalse(mediumPool.contains(lowMessage199), "199 pts should produce a low-level message")

        // 200 pts should be in medium
        let mediumMessage200 = MotivationalMessageProvider.message(activityPoints: 200, date: testDate)
        let lowPool = MotivationalMessageProvider.messages(time: .morning, level: .low)
        XCTAssertFalse(lowPool.contains(mediumMessage200), "200 pts should produce a medium-level message")
        XCTAssertFalse(highPool.contains(mediumMessage200), "200 pts should produce a medium-level message")

        // 400 pts should be in high
        let highMessage400 = MotivationalMessageProvider.message(activityPoints: 400, date: testDate)
        XCTAssertFalse(lowPool.contains(highMessage400), "400 pts should produce a high-level message")
        XCTAssertFalse(mediumPool.contains(highMessage400), "400 pts should produce a high-level message")
    }

    // MARK: - Day stability

    func testDayStabilityWithSameInputs() {
        let fixedDate = date(hour: 10) // morning
        let result1 = MotivationalMessageProvider.message(activityPoints: 150, date: fixedDate)
        let result2 = MotivationalMessageProvider.message(activityPoints: 150, date: fixedDate)
        XCTAssertEqual(result1, result2, "Same inputs should always produce the same message")
    }

    // MARK: - Different dates can produce different messages

    func testDifferentDatesCanProduceDifferentMessages() {
        // Pool has 10 messages, so day 0 and day 1 should index into different entries
        let epoch = Date(timeIntervalSince1970: 0) // UTC midnight Jan 1 1970 — day index 0
        // Pick a date 1 day later to get day index 1
        let epochPlusOneDay = Date(timeIntervalSince1970: 86400)

        // Use hour 8 (morning). startOfDay may shift the epoch-based dates into a different
        // local timezone day, so we force-set the hour for both.
        let date0 = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: epoch)!
        let date1 = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: epochPlusOneDay)!

        let pool = MotivationalMessageProvider.messages(time: .morning, level: .low)
        let dayIndex0 = Int(Calendar.current.startOfDay(for: date0).timeIntervalSince1970 / 86400)
        let dayIndex1 = Int(Calendar.current.startOfDay(for: date1).timeIntervalSince1970 / 86400)

        // Only run the assertion if the two indices map to different pool entries
        let entry0 = pool[((dayIndex0 % pool.count) + pool.count) % pool.count]
        let entry1 = pool[((dayIndex1 % pool.count) + pool.count) % pool.count]

        if entry0 != entry1 {
            let msg0 = MotivationalMessageProvider.message(activityPoints: 0, date: date0)
            let msg1 = MotivationalMessageProvider.message(activityPoints: 0, date: date1)
            XCTAssertNotEqual(msg0, msg1, "Consecutive days should typically rotate to a different message")
        }
        // If by coincidence they map to the same entry the test still passes (pool.count divides 1)
    }

    // MARK: - Message pool sizes

    func testMessagePoolSizes() {
        let times: [MotivationalMessageProvider.TimeOfDay] = [.morning, .afternoon, .evening, .night]
        let levels: [MotivationalMessageProvider.ActivityLevel] = [.low, .medium, .high]

        for time in times {
            for level in levels {
                let pool = MotivationalMessageProvider.messages(time: time, level: level)
                XCTAssertGreaterThanOrEqual(pool.count, 5,
                    "Pool for time=\(time), level=\(level) should have >= 5 messages, got \(pool.count)")
            }
        }
    }

    // MARK: - All messages in all pools are non-empty

    func testAllMessagesInAllPoolsAreNonEmpty() {
        let times: [MotivationalMessageProvider.TimeOfDay] = [.morning, .afternoon, .evening, .night]
        let levels: [MotivationalMessageProvider.ActivityLevel] = [.low, .medium, .high]

        for time in times {
            for level in levels {
                let pool = MotivationalMessageProvider.messages(time: time, level: level)
                for (index, message) in pool.enumerated() {
                    XCTAssertFalse(message.isEmpty,
                        "Message at index \(index) for time=\(time), level=\(level) should not be empty")
                }
            }
        }
    }

    // MARK: - TimeOfDay boundary tests

    func testNightBoundaryHours() {
        // hour=0 (midnight) → .night
        XCTAssertEqual(MotivationalMessageProvider.TimeOfDay.current(for: date(hour: 0)), .night)
        // hour=4 → .night
        XCTAssertEqual(MotivationalMessageProvider.TimeOfDay.current(for: date(hour: 4)), .night)
        // hour=5 → .morning
        XCTAssertEqual(MotivationalMessageProvider.TimeOfDay.current(for: date(hour: 5)), .morning)
    }

    func testAfternoonBoundary() {
        // hour=11 → .morning
        XCTAssertEqual(MotivationalMessageProvider.TimeOfDay.current(for: date(hour: 11)), .morning)
        // hour=12 → .afternoon
        XCTAssertEqual(MotivationalMessageProvider.TimeOfDay.current(for: date(hour: 12)), .afternoon)
    }

    func testEveningBoundary() {
        // hour=16 → .afternoon
        XCTAssertEqual(MotivationalMessageProvider.TimeOfDay.current(for: date(hour: 16)), .afternoon)
        // hour=17 → .evening
        XCTAssertEqual(MotivationalMessageProvider.TimeOfDay.current(for: date(hour: 17)), .evening)
        // hour=21 → .night
        XCTAssertEqual(MotivationalMessageProvider.TimeOfDay.current(for: date(hour: 21)), .night)
    }
}
