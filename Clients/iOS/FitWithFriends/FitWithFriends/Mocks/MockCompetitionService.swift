//
//  MockCompetitionService.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 1/22/22.
//

import Foundation

class MockCompetitionService: CompetitionService {
    var return_error: Error?

    init() {
        super.init(httpConnector: MockHttpConnector(), tokenManager: MockTokenManager())
    }

    var return_competitionOverview: CompetitionOverview?
    override func getCompetitionOverview(competitionId: UInt, completion: @escaping (Result<CompetitionOverview, Error>) -> Void) {
        DispatchQueue.global().asyncAfter(deadline: .now() + 1) { [weak self] in
            if let overview = self?.return_competitionOverview {
                completion(.success(overview))
            } else {
                completion(.failure(self?.return_error ?? HttpError.generic))
            }
        }
    }

    var return_usersCompetitions: [UInt]?
    override func getUsersCompetitions(userId: UInt, completion: @escaping (Result<[UInt], Error>) -> Void) {
        DispatchQueue.global().asyncAfter(deadline: .now() + 1) { [weak self] in
            if let competitions = self?.return_usersCompetitions {
                completion(.success(competitions))
            } else {
                completion(.failure(self?.return_error ?? HttpError.generic))
            }
        }
    }
}
