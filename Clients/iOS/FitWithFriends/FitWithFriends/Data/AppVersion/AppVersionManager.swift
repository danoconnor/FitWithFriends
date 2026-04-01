//
//  AppVersionManager.swift
//  FitWithFriends
//

import Combine
import Foundation

class AppVersionManager: IAppVersionManager, ObservableObject {
    private let appMetadataService: IAppMetadataService

    @Published private(set) var versionAlertState: AppVersionAlertState = .none
    var versionAlertStatePublisher: Published<AppVersionAlertState>.Publisher { $versionAlertState }

    init(appMetadataService: IAppMetadataService) {
        self.appMetadataService = appMetadataService
    }

    func checkAppVersion() async {
        guard let currentBuild = Bundle.main.infoDictionary?["CFBundleVersion"] as? String else {
            Logger.traceWarning(message: "Could not read CFBundleVersion from bundle")
            return
        }

        do {
            let versions = try await appMetadataService.getIosBuildVersions()
            let newState = determineAlertState(currentBuild: currentBuild, versions: versions)

            await MainActor.run {
                versionAlertState = newState
            }
        } catch {
            Logger.traceError(message: "Failed to check app version", error: error)
        }
    }

    func determineAlertState(currentBuild: String, versions: IosBuildVersionsDTO) -> AppVersionAlertState {
        if compareSemanticVersions(currentBuild, versions.requiredBuild) == .orderedAscending {
            return .requiredUpdate
        } else if compareSemanticVersions(currentBuild, versions.recommendedBuild) == .orderedAscending {
            return .recommendedUpdate
        } else {
            return .none
        }
    }
}
