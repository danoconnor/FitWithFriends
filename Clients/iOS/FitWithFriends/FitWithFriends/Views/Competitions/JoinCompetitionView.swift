//
//  JoinCompetitionView.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 2/21/22.
//

import SwiftUI

struct JoinCompetitionView: View {
    private let homepageSheetViewModel: HomepageSheetViewModel
    private let objectGraph: IObjectGraph

    @ObservedObject
    private var viewModel: JoinCompetitionViewModel

    @State var joinLoading = false

    init(homepageSheetViewModel: HomepageSheetViewModel, objectGraph: IObjectGraph) {
        self.homepageSheetViewModel = homepageSheetViewModel
        self.objectGraph = objectGraph
        viewModel = JoinCompetitionViewModel(appProtocolHandler: objectGraph.appProtocolHandler,
                                             competitionManager: objectGraph.competitionManager,
                                             homepageSheetViewModel: homepageSheetViewModel)
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if viewModel.isLoading {
                    Spacer()
                    ProgressView("Loading competition...")
                        .padding()
                    Spacer()
                } else {
                    if viewModel.state.isFailed {
                        FWFErrorBanner(message: viewModel.state.errorMessage)
                            .padding(.top, 8)
                    }

                    // Competition info card
                    VStack(alignment: .leading, spacing: 14) {
                        Label {
                            Text(viewModel.competitionName)
                                .font(.title3.weight(.semibold))
                        } icon: {
                            Image(systemName: "trophy.fill")
                                .foregroundStyle(Color("FwFBrandingColor"))
                        }

                        Label {
                            Text(viewModel.adminName)
                        } icon: {
                            Image(systemName: "person.fill")
                                .foregroundStyle(.secondary)
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                        Divider()

                        Label {
                            Text(viewModel.competitionDateRange)
                        } icon: {
                            Image(systemName: "calendar")
                                .foregroundStyle(.secondary)
                        }
                        .font(.subheadline)

                        Label {
                            Text(viewModel.competitionMembers)
                        } icon: {
                            Image(systemName: "person.3.fill")
                                .foregroundStyle(.secondary)
                        }
                        .font(.subheadline)
                    }
                    .fwfCard()
                    .padding(.horizontal, 16)
                    .padding(.top, 16)

                    Spacer()

                    VStack(spacing: 12) {
                        FWFPrimaryButton("Join") {
                            joinLoading = true
                            Task.detached {
                                await self.viewModel.joinCompetition()

                                await MainActor.run {
                                    self.joinLoading = false
                                }
                            }
                        }
                        .disabled(joinLoading)

                        Button("No thanks") {
                            objectGraph.appProtocolHandler.clearProtocolData()
                            homepageSheetViewModel.updateState(sheet: .joinCompetition, state: false)
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Join this competition?")
        }
        .presentationDragIndicator(.visible)
    }
}

struct JoinCompetitionView_Previews: PreviewProvider {
    static var previews: some View {
        JoinCompetitionView(homepageSheetViewModel: HomepageSheetViewModel(appProtocolHandler: MockAppProtocolHandler(),
                                                                          healthKitManager: MockHealthKitManager()),
                           objectGraph: MockObjectGraph())
    }
}
