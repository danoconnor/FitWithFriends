//
//  IAppMetadataService.swift
//  FitWithFriends
//

import Foundation

protocol IAppMetadataService {
    func getIosBuildVersions() async throws -> IosBuildVersionsDTO
}
