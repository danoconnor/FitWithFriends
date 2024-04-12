//
//  ActivityDataService.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 12/28/20.
//

import Foundation

public class ActivityDataService: ServiceBase, IActivityDataService {
    /// Apple's HealthKit APIs still use the completion block architecture, so add this wrapper to make things work smoothly
    public func reportActivitySummaries(_ activitySummaries: [ActivitySummary], completion: @escaping (Error?) -> Void) {
        guard activitySummaries.count > 0 else {
            Logger.traceInfo(message: "No activity summaries to report")
            completion(nil)
            return
        }

        Task.detached { [weak self] in
            guard let self = self else { return }
            do {
                try await self.reportActivitySummaries(activitySummaries)
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }

    public func reportWorkouts(_ workouts: [Workout], completion: @escaping (Error?) -> Void) {
        guard workouts.count > 0 else {
            Logger.traceInfo(message: "No workouts to report")
            completion(nil)
            return
        }

        Task.detached { [weak self] in
            guard let self = self else { return }
            do {
                try await self.reportWorkouts(workouts)
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }

    private func reportActivitySummaries(_ activitySummaries: [ActivitySummary]) async throws {
        let requestBody = try getRequestBody(for: activitySummaries)
        let _: EmptyResponse = try await makeRequestWithUserAuthentication(url: "\(SecretConstants.serviceBaseUrl)/activityData/dailySummary",
                                                                           method: .post,
                                                                           body: requestBody)
    }

    private func reportWorkouts(_ workouts: [Workout]) async throws {
        let requestBody = try getRequestBody(for: workouts)
        let _: EmptyResponse = try await makeRequestWithUserAuthentication(url: "\(SecretConstants.serviceBaseUrl)/activityData/workouts",
                                                                           method: .post,
                                                                           body: requestBody)
    }

    private func getRequestBody<T>(for entities: [T]) throws -> [String: String] where T : Encodable {
        let encodedData = try JSONEncoder.fwfDefaultEncoder.encode(entities)
        let jsonData = try JSONSerialization.jsonObject(with: encodedData, options: .allowFragments)

        guard let anyDict = jsonData as? [String: Any] else {
            Logger.traceError(message: "Failed to convert workout array to JSON")
            throw HttpError.generic
        }

        return anyDict.mapValues { String(describing: $0) }
    }
}
