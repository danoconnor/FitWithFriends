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

    // Local scoring config state — the full rule is rebuilt before submission.
    @State private var ruleKind: ScoringRules.Kind = .rings

    // Rings config
    @State private var includeCalories: Bool = true
    @State private var includeExercise: Bool = true
    @State private var includeStand: Bool = true
    @State private var enforceMinGoals: Bool = false
    @State private var minCaloriesText: String = "300"
    @State private var minExerciseText: String = "20"
    @State private var minStandText: String = "8"
    @State private var dailyCapText: String = ""

    // Workouts config
    @State private var workoutMetric: WorkoutMetric = .distance
    @State private var selectedActivityTypes: Set<UInt> = []

    // Daily config
    @State private var dailyMetric: DailyMetric = .steps

    @State private var showingActivityTypePicker = false
    @State private var showingTypeInfo = false
    @State private var showingProUpgrade = false
    @FocusState private var nameFieldFocused: Bool

    private let homepageSheetViewModel: HomepageSheetViewModel
    private let subscriptionManager: ISubscriptionManager
    private let serverEnvironmentManager: IServerEnvironmentManager
    private let maxCompetitionLengthInDays: Double = 30

    init(homepageSheetViewModel: HomepageSheetViewModel, objectGraph: IObjectGraph) {
        self.homepageSheetViewModel = homepageSheetViewModel
        self.subscriptionManager = objectGraph.subscriptionManager
        self.serverEnvironmentManager = objectGraph.serverEnvironmentManager
        _viewModel = StateObject(wrappedValue: CreateCompetitionViewModel(authenticationManager: objectGraph.authenticationManager,
                                                                          competitionManager: objectGraph.competitionManager,
                                                                          subscriptionManager: objectGraph.subscriptionManager,
                                                                          homepageSheetViewModel: homepageSheetViewModel))
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ScrollView {
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
                                    .submitLabel(.done)
                                    .focused($nameFieldFocused)
                                    .onSubmit { nameFieldFocused = false }
                            }

                            // Date pickers
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Duration")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.secondary)

                                DatePicker("Start date",
                                           selection: $startDate,
                                           in: Date()...,
                                           displayedComponents: .date)

                                DatePicker("End date",
                                           selection: $endDate,
                                           in: ClosedRange(uncheckedBounds: (startDate + .xtDays(1), startDate + .xtDays(maxCompetitionLengthInDays))),
                                           displayedComponents: .date)
                            }

                            // Scoring rule configuration
                            scoringSection
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 24)
                    }
                }

                if requiresProUserMissing {
                    Text("Custom scoring rules require a Pro subscription")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)

                    FWFPrimaryButton("Upgrade to Pro") {
                        showingProUpgrade = true
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                } else {
                    FWFPrimaryButton("Create") {
                        viewModel.scoringRules = buildRule()
                        viewModel.createCompetition(competitionName: competitionName,
                                                    startDate: startDate,
                                                    endDate: endDate)
                    }
                    .disabled(viewModel.state == .inProgress || competitionName.isEmpty)
                    .opacity(competitionName.isEmpty ? 0.5 : 1.0)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Create competition")
        }
        .presentationDragIndicator(.visible)
        .sheet(isPresented: $showingActivityTypePicker) {
            ActivityTypePickerView(selected: $selectedActivityTypes)
        }
        .sheet(isPresented: $showingProUpgrade) {
            ProUpgradeView(homepageSheetViewModel: homepageSheetViewModel,
                           subscriptionManager: subscriptionManager,
                           serverEnvironmentManager: serverEnvironmentManager)
        }
    }

    // MARK: - Scoring section

    @ViewBuilder
    private var scoringSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Text("Scoring")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                Button {
                    showingTypeInfo = true
                } label: {
                    Image(systemName: "questionmark.circle")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showingTypeInfo) {
                    Text(ruleKind.description)
                        .font(.subheadline)
                        .padding()
                        .presentationCompactAdaptation(.popover)
                }
            }

            Menu {
                Picker("Scoring rule", selection: $ruleKind) {
                    Text("Activity Rings").tag(ScoringRules.Kind.rings)
                    Text("Tracked Workouts").tag(ScoringRules.Kind.workouts)
                    Text("Daily Totals").tag(ScoringRules.Kind.daily)
                }
            } label: {
                HStack(spacing: 4) {
                    Text(ruleKind.displayName)
                        .font(.body)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2)
                }
                .foregroundStyle(.primary)
            }

            switch ruleKind {
            case .rings:
                ringsConfig
            case .workouts:
                workoutsConfig
            case .daily:
                dailyConfig
            }
        }
    }

    @ViewBuilder
    private var ringsConfig: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Which rings count?")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Toggle("Move (calories)", isOn: $includeCalories)
            Toggle("Exercise", isOn: $includeExercise)
            Toggle("Stand", isOn: $includeStand)

            Toggle("Enforce minimum goals", isOn: $enforceMinGoals)
                .padding(.top, 4)

            if enforceMinGoals {
                if includeCalories {
                    labelledNumberField(label: "Min calorie goal", text: $minCaloriesText, placeholder: "300", suffix: "cal")
                }
                if includeExercise {
                    labelledNumberField(label: "Min exercise goal", text: $minExerciseText, placeholder: "20", suffix: "min")
                }
                if includeStand {
                    labelledNumberField(label: "Min stand goal", text: $minStandText, placeholder: "8", suffix: "hr")
                }

                if hasIncompleteMinGoals {
                    Text("Enter a minimum for each included ring")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            labelledNumberField(label: "Daily cap (optional)", text: $dailyCapText, placeholder: "\(includedRingCount * 200)", suffix: "pts")

            if includedRingCount == 0 {
                Text("Select at least one ring")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }

    @ViewBuilder
    private var workoutsConfig: some View {
        VStack(alignment: .leading, spacing: 10) {
            Picker("Metric", selection: $workoutMetric) {
                Text("Calories").tag(WorkoutMetric.calories)
                Text("Minutes").tag(WorkoutMetric.duration)
                Text("Distance").tag(WorkoutMetric.distance)
            }
            .pickerStyle(.segmented)

            Button {
                showingActivityTypePicker = true
            } label: {
                HStack {
                    Text("Workout types")
                    Spacer()
                    Text(selectedActivityTypes.isEmpty ? "Any" : "\(selectedActivityTypes.count) selected")
                        .foregroundStyle(.secondary)
                    Image(systemName: "chevron.right").foregroundStyle(.tertiary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Workout types")
        }
    }

    @ViewBuilder
    private var dailyConfig: some View {
        Picker("Metric", selection: $dailyMetric) {
            Text("Steps").tag(DailyMetric.steps)
            Text("Walking/Running Distance").tag(DailyMetric.walkingRunningDistance)
        }
        .pickerStyle(.segmented)
    }

    @ViewBuilder
    private func labelledNumberField(label: String, text: Binding<String>, placeholder: String, suffix: String) -> some View {
        HStack {
            Text(label).font(.footnote)
            Spacer()
            TextField(placeholder, text: text)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 100)
                .textFieldStyle(.roundedBorder)
            Text(suffix)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(width: 32, alignment: .leading)
        }
    }

    // MARK: - Rule assembly + gating

    private var includedRingCount: Int {
        [includeCalories, includeExercise, includeStand].filter { $0 }.count
    }

    /// True when `enforceMinGoals` is on but a value is missing for a ring the user included —
    /// silently treating empty fields as "no minimum" surprised early testers, so block submit
    /// and surface the gap inline.
    private var hasIncompleteMinGoals: Bool {
        guard ruleKind == .rings && enforceMinGoals else { return false }
        if includeCalories && Int(minCaloriesText) == nil { return true }
        if includeExercise && Int(minExerciseText) == nil { return true }
        if includeStand && Int(minStandText) == nil { return true }
        return false
    }

    /// Custom rules require Pro — block submit for free users on anything but the default.
    private var requiresProUserMissing: Bool {
        guard !viewModel.isUserPro else { return false }
        if ruleKind != .rings { return true }
        // Even a rings rule counts as custom when something is changed away from default.
        let hasCustomRingsConfig = includedRingCount < ScoringRing.allCases.count
            || enforceMinGoals
            || (Int(dailyCapText) ?? 0) > 0
        return hasCustomRingsConfig
    }

    private var canSubmit: Bool {
        if ruleKind == .rings && includedRingCount == 0 { return false }
        if hasIncompleteMinGoals { return false }
        if requiresProUserMissing { return false }
        return true
    }

    private func buildRule() -> ScoringRules {
        switch ruleKind {
        case .rings:
            var rings: Set<ScoringRing> = []
            if includeCalories { rings.insert(.calories) }
            if includeExercise { rings.insert(.exercise) }
            if includeStand { rings.insert(.stand) }

            var minGoals: RingMinGoals? = nil
            if enforceMinGoals {
                minGoals = RingMinGoals(
                    calories: includeCalories ? Int(minCaloriesText) : nil,
                    exerciseTime: includeExercise ? Int(minExerciseText) : nil,
                    standTime: includeStand ? Int(minStandText) : nil
                )
            }

            let cap = Int(dailyCapText).flatMap { $0 > 0 ? $0 : nil }
            let includedFull = rings == Set(ScoringRing.allCases)

            // Normalise to `.default` when nothing meaningful was customised — this keeps free
            // users out of the Pro gate when they leave the section untouched.
            if includedFull && minGoals == nil && cap == nil {
                return .default
            }
            return .rings(includedRings: rings, minGoals: minGoals, dailyCap: cap)

        case .workouts:
            let types = selectedActivityTypes.isEmpty ? nil : Array(selectedActivityTypes).sorted()
            return .workouts(metric: workoutMetric, activityTypes: types)

        case .daily:
            return .daily(metric: dailyMetric)
        }
    }
}

// MARK: - Activity type multi-select

struct ActivityTypePickerView: View {
    @Binding var selected: Set<UInt>
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                Button {
                    selected.removeAll()
                } label: {
                    HStack {
                        Text("Any workout type")
                            .foregroundStyle(.primary)
                        Spacer()
                        if selected.isEmpty {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.tint)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                ForEach(WorkoutActivityTypeCatalog.commonEntries) { entry in
                    Button {
                        if selected.contains(entry.rawValue) {
                            selected.remove(entry.rawValue)
                        } else {
                            selected.insert(entry.rawValue)
                        }
                    } label: {
                        HStack {
                            Text(entry.displayName)
                                .foregroundStyle(.primary)
                            Spacer()
                            if selected.contains(entry.rawValue) {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.tint)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("Workout types")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct CreateCompetitionView_Previews: PreviewProvider {
    static var previews: some View {
        CreateCompetitionView(homepageSheetViewModel: HomepageSheetViewModel(appProtocolHandler: MockAppProtocolHandler(),
                                                                             healthKitManager: MockHealthKitManager()),
        objectGraph: MockObjectGraph())
    }
}
