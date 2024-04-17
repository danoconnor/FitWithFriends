//
//  ActivityDataService.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 12/28/20.
//

import Foundation

public class ActivityDataService: ServiceBase, IActivityDataService {
    /// Apple's HealthKit APIs still use the completion block pattern, so add this wrapper to make things work smoothly
    public func reportActivitySummaries(_ activitySummaries: [ActivitySummary], completion: @escaping (Error?) -> Void) {
        guard activitySummaries.count > 0 else {
            Logger.traceInfo(message: "No activity summaries to report")
            completion(nil)
            return
        }

        Task.detached {
            do {
                try await self.reportActivitySummaries(activitySummaries)
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }

    /// Apple's HealthKit APIs still use the completion block pattern, so add this wrapper to make things work smoothly
    public func reportWorkouts(_ workouts: [Workout], completion: @escaping (Error?) -> Void) {
        guard workouts.count > 0 else {
            Logger.traceInfo(message: "No workouts to report")
            completion(nil)
            return
        }

        Task.detached {
            do {
                try await self.reportWorkouts(workouts)
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }

    private func reportActivitySummaries(_ activitySummaries: [ActivitySummary]) async throws {
        let _: EmptyResponse = try await makeRequestWithUserAuthentication(url: "\(serverEnvironmentManager.baseUrl)/activityData/dailySummary",
                                                                           method: .post,
                                                                           body: ValueArrayDTO(values: activitySummaries))
    }

    private func reportWorkouts(_ workouts: [Workout]) async throws {
        let _: EmptyResponse = try await makeRequestWithUserAuthentication(url: "\(serverEnvironmentManager.baseUrl)/activityData/workouts",
                                                                           method: .post,
                                                                           body: ValueArrayDTO(values: workouts))
    }
}
