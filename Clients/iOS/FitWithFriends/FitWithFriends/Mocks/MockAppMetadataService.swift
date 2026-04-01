//
//  MockAppMetadataService.swift
//  FitWithFriends
//

import Foundation

class MockAppMetadataService: IAppMetadataService {
    var getIosBuildVersionsCallCount = 0
    var return_getIosBuildVersions: IosBuildVersionsDTO?
    var return_getIosBuildVersions_error: Error?

    init() {}

    func getIosBuildVersions() async throws -> IosBuildVersionsDTO {
        getIosBuildVersionsCallCount += 1

        if let error = return_getIosBuildVersions_error {
            throw error
        }

        if let retVal = return_getIosBuildVersions {
            return retVal
        } else {
            throw HttpError.generic
        }
    }
}
