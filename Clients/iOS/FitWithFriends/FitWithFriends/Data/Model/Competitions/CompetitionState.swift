//
//  CompetitionState.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 8/13/25.
//

import Foundation

public enum CompetitionState: Int, Codable {
    /// State is unknown
    case unknown = 0

    /// The competition has not started yet or is currently active
    /// This is the default state when a new competition is created
    case notStartedOrActive = 1

    /// The competition has recently ended and the results are being processed
    /// We set this state when our daily cron job sends the push notifications to users
    /// telling them that the competition has ended
    case processingResults = 2

    /// The competition has ended and the results are available
    /// The results have been moved to the archive table in the database
    /// We set this state when our daily cron job sends the final results push notifications
    case archived = 3
}
