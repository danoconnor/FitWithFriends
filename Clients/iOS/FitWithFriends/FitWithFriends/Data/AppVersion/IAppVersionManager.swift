//
//  IAppVersionManager.swift
//  FitWithFriends
//

import Combine
import Foundation

enum AppVersionAlertState: Equatable {
    case none
    case recommendedUpdate
    case requiredUpdate
}

protocol IAppVersionManager: AnyObject {
    var versionAlertState: AppVersionAlertState { get }
    var versionAlertStatePublisher: Published<AppVersionAlertState>.Publisher { get }
    func checkAppVersion() async
}
