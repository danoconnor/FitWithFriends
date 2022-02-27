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
        VStack(alignment: .leading) {
            Text("Join this competition?")
                .font(.largeTitle)
                .padding()

            if viewModel.isLoading {
                Spacer()

                HStack {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(.circular)
                        .padding()
                    Spacer()
                }

                Spacer()
            } else {
                VStack(alignment: .leading) {
                    Text(viewModel.competitionName)
                        .font(.title3)
                    Text(viewModel.adminName)
                        .font(.title3)
                        .padding(.bottom)
                    
                    Text(viewModel.competitionDateRange)
                        .font(.title3)
                    Text(viewModel.competitionMembers)
                        .font(.title3)
                }
                .padding()

                Spacer()

                VStack(alignment: .center) {
                    Button("Join") {
                        joinLoading = true
                        Task.detached {
                            // TODO: error handling
                            _ = await self.viewModel.joinCompetition()

                            await MainActor.run {
                                self.joinLoading = false
                            }
                        }
                    }
                    .font(.title2)
                    .padding(.bottom)
                    .disabled(joinLoading)

                    Button("No thanks") {
                        objectGraph.appProtocolHandler.clearProtocolData()
                        homepageSheetViewModel.updateState(sheet: .joinCompetition, state: false)
                    }
                    .padding(.bottom)
                }
                .frame(maxWidth: .infinity)
            }

        }
        .padding()
    }
}

struct JoinCompetitionView_Previews: PreviewProvider {
    static var previews: some View {
        JoinCompetitionView(homepageSheetViewModel: HomepageSheetViewModel(appProtocolHandler: MockAppProtocolHandler(),
                                                                          healthKitManager: MockHealthKitManager()),
                           objectGraph: MockObjectGraph())
    }
}
