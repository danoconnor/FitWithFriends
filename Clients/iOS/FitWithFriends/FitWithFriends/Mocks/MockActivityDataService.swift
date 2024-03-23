//
//  MockActivityDataService.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 1/22/22.
//

import Foundation

class MockActivityDataService: ActivityDataService {
    var return_error: Error?
    init() {
        super.init(httpConnector: MockHttpConnector(), tokenManager: MockTokenManager())
    }

    override func reportActivitySummaries(_ activitySummaries: [ActivitySummary], completion: @escaping (Error?) -> Void) {
        DispatchQueue.global().asyncAfter(deadline: .now() + 1) { [weak self] in
            completion(self?.return_error)
        }
    }
}
