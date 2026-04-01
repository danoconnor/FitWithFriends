//
//  AppVersionViewModel.swift
//  FitWithFriends
//

import Combine
import Foundation

class AppVersionViewModel: ObservableObject {
    @Published var alertState: AppVersionAlertState = .none

    private let appVersionManager: IAppVersionManager
    private var cancellable: AnyCancellable?

    init(appVersionManager: IAppVersionManager) {
        self.appVersionManager = appVersionManager

        cancellable = appVersionManager.versionAlertStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newState in
                self?.alertState = newState
            }
    }

    func dismissRecommendedAlert() {
        alertState = .none
    }
}
