//
//  CompetitionDetailView.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 1/23/22.
//

import Combine
import SwiftUI

struct CompetitionOverviewView: View {
    private let showAllDetails: Bool

    private let competitionOverview: CompetitionOverview
    private let homepageSheetViewModel: HomepageSheetViewModel
    @ObservedObject private var viewModel: CompetitionOverviewViewModel

    @State private var actionInProgress = false

    init(objectGraph: IObjectGraph, competitionOverview: CompetitionOverview, homepageSheetViewModel: HomepageSheetViewModel, showAllDetails: Bool) {
        self.competitionOverview = competitionOverview
        self.homepageSheetViewModel = homepageSheetViewModel
        self.showAllDetails = showAllDetails
        viewModel = CompetitionOverviewViewModel(authenticationManager: objectGraph.authenticationManager,
                                                 competitionManager: objectGraph.competitionManager,
                                                 competitionOverview: competitionOverview, serverEnrivonmentManager: objectGraph.serverEnvironmentManager,
                                                 showAllDetails: showAllDetails)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: title + menu
            HStack(alignment: .top) {
                // Tappable title with chevron
                Button {
                    if !showAllDetails {
                        homepageSheetViewModel.updateState(sheet: .competitionDetails,
                                                           state: true,
                                                           contextData: competitionOverview)
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(viewModel.competitionName)
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)

                        if competitionOverview.isPublic {
                            Label("Public", systemImage: "globe")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(Color("FwFBrandingColor"))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(Color("FwFBrandingColor").opacity(0.12)))
                        } else {
                            Label("Private", systemImage: "lock.fill")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(Color(.tertiarySystemFill)))
                        }

                        if !showAllDetails {
                            Image(systemName: "chevron.right")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
                .buttonStyle(.plain)

                Spacer()

                // Action menu
                Menu {
                    ForEach(viewModel.availableActions.sorted(), id: \.self) { action in
                        Button(action.description) {
                            self.actionInProgress = true
                            Task.detached {
                                await self.viewModel.performAction(action)

                                await MainActor.run {
                                    self.actionInProgress = false
                                }
                            }
                        }
                        .disabled(actionInProgress)
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(Color(.tertiarySystemFill))
                        )
                }
            }

            // Metadata: position pill + visibility badge + dates
            HStack(spacing: 10) {
                Text(viewModel.userPositionDescription)
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color("FwFBrandingColor").opacity(0.12))
                    )

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption)
                    Text(viewModel.competitionDatesDescription)
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }

            Divider()

            // Leaderboard
            VStack(spacing: 2) {
                ForEach(0 ..< viewModel.results.count, id: \.self) { position in
                    let result = viewModel.results[position]
                    UserCompetitionResultView(result: result,
                                              isCompetitionActive: viewModel.isCompetitionActive)
                        .contextMenu {
                            let availableActions = self.viewModel.getUserContextMenuActions(for: result.userCompetitionPoints.userId)

                            ForEach(availableActions, id: \.self) { action in
                                Button(action.description) {
                                    Task.detached {
                                        await self.viewModel.performAction(action)
                                    }
                                }
                            }
                        }
                }
            }
        }
        .sheet(isPresented: $viewModel.shouldShowSheet, content: {
            if let shareUrl = viewModel.shareUrl {
                ShareSheet(url: shareUrl)
            }
        })
        .alert("Are you sure?", isPresented: $viewModel.shouldShowAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Confirm", role: .destructive) {
                Task.detached {
                    await self.viewModel.deleteCompetitionConfirmed()
                }
            }
        } message: {
            Text("This will permanently delete the competition for all users.")
        }
    }
}

struct CompetitionOverviewView_Previews: PreviewProvider {
    private static var competitionOverview: CompetitionOverview {
        let results = [
            UserCompetitionPoints(userId: "user_0", firstName: "Test", lastName: "User 0", total: 400, today: 110),
            UserCompetitionPoints(userId: "user_1", firstName: "Test", lastName: "User 1", total: 300, today: 125),
            UserCompetitionPoints(userId: "user_2", firstName: "Test", lastName: "User 2", total: 425, today: 75),
            UserCompetitionPoints(userId: "user_3", firstName: "Test", lastName: "User 3", total: 100, today: 0),
            UserCompetitionPoints(userId: "user_4", firstName: "Test", lastName: "User 4", total: 50, today: 0),
            UserCompetitionPoints(userId: "user_5", firstName: "Test", lastName: "User 5", total: 10, today: 10)
        ]

        return CompetitionOverview(
            //name: "Really really really long competition name",
            start: Date(),
            end: Date().addingTimeInterval(TimeInterval.xtDays(7)),
            currentResults: results)
    }

    static var previews: some View {
        CompetitionOverviewView(objectGraph: MockObjectGraph(),
                                competitionOverview: competitionOverview, homepageSheetViewModel: HomepageSheetViewModel(appProtocolHandler: MockAppProtocolHandler(), healthKitManager: MockHealthKitManager()),
                                showAllDetails: true)
            .fwfCard()
            .padding(.horizontal, 16)

        CompetitionOverviewView(objectGraph: MockObjectGraph(),
                                competitionOverview: competitionOverview, homepageSheetViewModel: HomepageSheetViewModel(appProtocolHandler: MockAppProtocolHandler(), healthKitManager: MockHealthKitManager()),
                                showAllDetails: false)
            .fwfCard()
            .padding(.horizontal, 16)
    }
}
