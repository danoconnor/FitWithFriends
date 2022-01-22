//
//  MockCompetitionManager.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 1/22/22.
//

import Foundation

class MockCompetitionManager: CompetitionManager {
    var return_error: Error?

    init() {
        super.init(authenticationManager: MockAuthenticationManager(), competitionService: MockCompetitionService())
    }

    override func createCompetition(startDate: Date, endDate: Date, competitionName: String, completion: @escaping (Error?) -> Void) {
        DispatchQueue.global().asyncAfter(deadline: .now() + 1) { [weak self] in
            completion(self?.return_error)
        }
    }
}
