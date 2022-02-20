//
//  ActivityDataService.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 12/28/20.
//

import Foundation

class ActivityDataService: ServiceBase {
    func reportActivitySummary(activitySummary: ActivitySummary) async -> Error? {
        guard let requestBody = activitySummary.xtDictionary else {
            Logger.traceError(message: "Failed to get dictionary for activity summary")
            return HttpError.generic
        }

        let result: Result<EmptyResponse, Error> = await makeRequestWithUserAuthentication(url: "\(SecretConstants.serviceBaseUrl)/activityData/dailySummary",
                                                                                           method: .post,
                                                                                           body: requestBody)
        return result.xtError
    }

    /// Apple's HealthKit APIs still use the completion block architecture, so add this wrapper to make things work smoothly
    func reportActivitySummary(activitySummary: ActivitySummary, completion: @escaping (Error?) -> Void) {
        Task.detached { [weak self] in
            guard let self = self else { return }
            let error = await self.reportActivitySummary(activitySummary: activitySummary)
            completion(error)
        }
    }
}
