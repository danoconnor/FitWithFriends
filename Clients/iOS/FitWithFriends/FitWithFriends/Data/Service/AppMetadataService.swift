//
//  AppMetadataService.swift
//  FitWithFriends
//

import Foundation

class AppMetadataService: IAppMetadataService {
    private let httpConnector: IHttpConnector
    private let serverEnvironmentManager: IServerEnvironmentManager

    init(httpConnector: IHttpConnector,
         serverEnvironmentManager: IServerEnvironmentManager) {
        self.httpConnector = httpConnector
        self.serverEnvironmentManager = serverEnvironmentManager
    }

    func getIosBuildVersions() async throws -> IosBuildVersionsDTO {
        let url = "\(serverEnvironmentManager.baseUrl)/appMetadata/iosBuildVersions"
        return try await httpConnector.makeRequest(url: url, method: .get)
    }
}
