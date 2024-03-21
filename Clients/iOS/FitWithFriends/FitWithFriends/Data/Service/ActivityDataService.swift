//
//  ActivityDataService.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 12/28/20.
//

import Foundation

class ActivityDataService: ServiceBase {
    func reportActivitySummaries(activitySummaries: [ActivitySummary]) async -> Error? {
        let encodedData: Data
        let jsonData: Any
        do {
            encodedData = try JSONEncoder.fwfDefaultEncoder.encode(activitySummaries)
            jsonData = try JSONSerialization.jsonObject(with: encodedData, options: .allowFragments)
        } catch {
            return error
        }

        guard let anyDict = jsonData as? [String: Any] else {
            Logger.traceError(message: "Failed to convert activity summary array to JSON")
            return HttpError.generic
        }
        
        let requestBody = anyDict.mapValues { String(describing: $0) }
        let result: Result<EmptyResponse, Error> = await makeRequestWithUserAuthentication(url: "\(SecretConstants.serviceBaseUrl)/activityData/dailySummary",
                                                                                           method: .post,
                                                                                           body: requestBody)
        return result.xtError
    }

    /// Apple's HealthKit APIs still use the completion block architecture, so add this wrapper to make things work smoothly
    func reportActivitySummaries(activitySummaries: [ActivitySummary], completion: @escaping (Error?) -> Void) {
        Task.detached { [weak self] in
            guard let self = self else { return }
            let error = await self.reportActivitySummaries(activitySummaries: activitySummaries)
            completion(error)
        }
    }
}
