//
//  WatchRootView.swift
//  FitWithFriends Watch App
//
//  Created by Dan O'Connor on 4/14/26.
//

import SwiftUI

struct WatchRootView: View {
    @ObservedObject var objectGraph: WatchObjectGraph
    @StateObject private var viewModel: CompetitionsPagerViewModel
    @Environment(\.scenePhase) private var scenePhase

    private let refreshThrottle = WatchRefreshThrottle()

    init(objectGraph: WatchObjectGraph) {
        self.objectGraph = objectGraph
        _viewModel = StateObject(wrappedValue: CompetitionsPagerViewModel(
            authenticationManager: objectGraph.authenticationManager,
            competitionManager: objectGraph.competitionManager
        ))
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Competitions")
        }
        .onAppear {
            refreshIfNeeded()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                refreshIfNeeded()
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.displayState {
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityIdentifier("loadingView")
        case .signedOut:
            SignedOutView()
        case .noCompetitions:
            NoCompetitionsView()
        case let .competitions(overviews):
            CompetitionsPagerView(
                overviews: overviews,
                currentUserId: objectGraph.authenticationManager.loggedInUserId,
                onRefresh: { await forceRefresh() }
            )
        }
    }

    private func refreshIfNeeded() {
        guard refreshThrottle.shouldRefresh() else { return }
        Task.detached {
            await objectGraph.competitionManager.refreshCompetitionOverviews()
        }
    }

    private func forceRefresh() async {
        refreshThrottle.invalidate()
        await objectGraph.competitionManager.refreshCompetitionOverviews()
    }
}
