//
//  MockActivityDataService.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 1/22/22.
//

import Foundation

public class MockActivityDataService: ActivityDataService {
    public var return_error: Error?
    public init() {
        super.init(httpConnector: MockHttpConnector(), tokenManager: MockTokenManager())
    }

    override public func reportActivitySummaries(_ activitySummaries: [ActivitySummary], completion: @escaping (Error?) -> Void) {
        DispatchQueue.global().asyncAfter(deadline: .now() + 1) { [weak self] in
            completion(self?.return_error)
        }
    }
}
