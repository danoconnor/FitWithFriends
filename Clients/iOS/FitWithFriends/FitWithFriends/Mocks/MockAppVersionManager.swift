//
//  MockAppVersionManager.swift
//  FitWithFriends
//

import Combine
import Foundation

class MockAppVersionManager: IAppVersionManager {
    @Published var return_versionAlertState: AppVersionAlertState = .none
    var versionAlertState: AppVersionAlertState { return_versionAlertState }
    var versionAlertStatePublisher: Published<AppVersionAlertState>.Publisher { $return_versionAlertState }

    var checkAppVersionCallCount = 0

    init() {}

    func checkAppVersion() async {
        checkAppVersionCallCount += 1
    }
}
