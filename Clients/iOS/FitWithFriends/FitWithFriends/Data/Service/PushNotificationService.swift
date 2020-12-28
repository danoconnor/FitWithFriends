//
//  PushNotificationService.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 12/28/20.
//

import Foundation

class PushNotificationService: ServiceBase {
    func registerApnsToken(token: String, completion: @escaping (Error?) -> Void) {
        let requestBody: [String: String] = [
            "pushToken": token
        ]

        makeRequestWithUserAuthentication(url: "\(SecretConstants.serviceBaseUrl)/pushNotification/register",
                                          method: .post,
                                          body: requestBody,
                                          completion: { (result: Result<EmptyReponse, Error>) in
                                            switch result {
                                            case let .failure(error):
                                                completion(error)
                                            default:
                                                completion(nil)
                                            }
                                          })
    }
}
