//
//  CreateCompetitionView.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 2/27/21.
//

import SwiftUI

struct CreateCompetitionView: View {
    @StateObject private var viewModel: CreateCompetitionViewModel

    @State var startDate = Date().addingTimeInterval(TimeInterval.xtDays(1))
    @State var endDate = Date().addingTimeInterval(TimeInterval.xtDays(8))
    @State var competitionName = ""

    private let maxCompetitionLengthInDays: Double = 30;

    init(homepageSheetViewModel: HomepageSheetViewModel, objectGraph: IObjectGraph) {
        _viewModel = StateObject(wrappedValue: CreateCompetitionViewModel(authenticationManager: objectGraph.authenticationManager,
                                                                          competitionManager: objectGraph.competitionManager,
                                                                          homepageSheetViewModel: homepageSheetViewModel))
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if viewModel.state.isFailed {
                    FWFErrorBanner(message: viewModel.state.errorMessage)
                        .padding(.top, 8)
                }

                VStack(alignment: .leading, spacing: 24) {
                    // Competition name field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Competition Name")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)

                        TextField("e.g., January Challenge", text: $competitionName)
                            .textFieldStyle(.roundedBorder)
                    }

                    // Date pickers
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Duration")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)

                        DatePicker("Start date",
                                   selection: $startDate,
                                   displayedComponents: .date)

                        DatePicker("End date",
                                   selection: $endDate,
                                   in: ClosedRange(uncheckedBounds: (startDate + .xtDays(1), startDate + .xtDays(maxCompetitionLengthInDays))),
                                   displayedComponents: .date)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 24)

                Spacer()

                FWFPrimaryButton("Create") {
                    viewModel.createCompetition(competitionName: competitionName,
                                                startDate: startDate,
                                                endDate: endDate)
                }
                .disabled(viewModel.state == .inProgress || competitionName.count == 0)
                .opacity(competitionName.count == 0 ? 0.5 : 1.0)
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .navigationTitle("Create competition")
        }
        .presentationDragIndicator(.visible)
    }
}

struct CreateCompetitionView_Previews: PreviewProvider {
    static var previews: some View {
        CreateCompetitionView(homepageSheetViewModel: HomepageSheetViewModel(appProtocolHandler: MockAppProtocolHandler(),
                                                                             healthKitManager: MockHealthKitManager()),
        objectGraph: MockObjectGraph())
    }
}
