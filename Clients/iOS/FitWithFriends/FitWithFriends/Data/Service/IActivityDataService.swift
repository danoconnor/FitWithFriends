//
//  IActivityDataService.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 3/25/24.
//

import Foundation

public protocol IActivityDataService {

    /// Report the given activity summaries to the backend, so they can be used in score calculations
    /// - Parameters:
    ///   - activitySummaries: The activity summaries to send/update
    ///   - completion: Completion block
    func reportActivitySummaries(_ activitySummaries: [ActivitySummary], completion: @escaping (Error?) -> Void)

    /// Report the given workouts to the backend, so they can be used in score calculations
    /// - Parameters:
    ///   - workouts: The workouts to send
    ///   - completion: Completion block
    func reportWorkouts(_ workouts: [Workout], completion: @escaping (Error?) -> Void)
}
