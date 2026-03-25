//
//  MockActivityDataService.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 1/22/22.
//

import Foundation

public class MockActivityDataService: IActivityDataService {
    public init() {}

    public var param_reportActivitySummaries_activitySummaries: [ActivitySummary]?
    public var return_reportActivitySummaries_error: Error?
    public var reportActivitySummariesCallCount = 0
    public func reportActivitySummaries(_ activitySummaries: [ActivitySummary], completion: @escaping (Error?) -> Void) {
        reportActivitySummariesCallCount += 1
        param_reportActivitySummaries_activitySummaries = activitySummaries

        DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
            completion(self.return_reportActivitySummaries_error)
        }
    }

    public var param_reportWorkouts_workouts: [Workout]?
    public var return_reportWorkouts_error: Error?
    public var reportWorkoutsCallCount = 0
    public func reportWorkouts(_ workouts: [Workout], completion: @escaping ((any Error)?) -> Void) {
        reportWorkoutsCallCount += 1
        param_reportWorkouts_workouts = workouts

        DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
            completion(self.return_reportWorkouts_error)
        }
    }
}
