//
//  ActivityDataService.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 12/28/20.
//

import Foundation

class ActivityDataService: ServiceBase {
    func reportActivitySummary(activitySummary: ActivitySummary, completion: @escaping (Error?) -> Void) {
        guard let requestBody = activitySummary.xtDictionary else {
            Logger.traceError(message: "Failed to get dictionary for activity summary")
            completion(HttpError.generic)
            return
        }

        makeRequestWithUserAuthentication(url: "\(SecretConstants.serviceBaseUrl)/activityData/dailySummary",
                                          method: .post,
                                          body: requestBody) { (result: Result<EmptyReponse, Error>) in
            switch result {
            case let .failure(error):
                completion(error)
            default:
                completion(nil)
            }
        }
    }

    func reportWorkout(workout: Workout, completion: @escaping (Error?) -> Void) {
        guard let requestBody = workout.xtDictionary else {
            Logger.traceError(message: "Failed to get dictionary for workout")
            completion(HttpError.generic)
            return
        }

        makeRequestWithUserAuthentication(url: "\(SecretConstants.serviceBaseUrl)/activityData/workout",
                                          method: .post,
                                          body: requestBody) { (result: Result<EmptyReponse, Error>) in
            switch result {
            case let .failure(error):
                completion(error)
            default:
                completion(nil)
            }
        }
    }
}
