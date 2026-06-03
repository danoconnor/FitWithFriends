//
//  CreateCompetitionView.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 2/27/21.
//
//  3-step wizard: Templates → Scoring → Invite. All rule state lives on the
//  CreateCompetitionViewModel so it survives step transitions. Pro modes are
//  soft-gated — free users can preview the configuration, the lock callout
//  surfaces in step 2, and submit is blocked at that point.
//

import SwiftUI

struct CreateCompetitionView: View {
    @StateObject private var viewModel: CreateCompetitionViewModel
    @State private var showingProUpgrade = false

    private let homepageSheetViewModel: HomepageSheetViewModel
    private let subscriptionManager: ISubscriptionManager
    private let serverEnvironmentManager: IServerEnvironmentManager
    private let objectGraph: IObjectGraph

    init(homepageSheetViewModel: HomepageSheetViewModel, objectGraph: IObjectGraph) {
        self.homepageSheetViewModel = homepageSheetViewModel
        self.objectGraph = objectGraph
        self.subscriptionManager = objectGraph.subscriptionManager
        self.serverEnvironmentManager = objectGraph.serverEnvironmentManager
        _viewModel = StateObject(wrappedValue: CreateCompetitionViewModel(authenticationManager: objectGraph.authenticationManager,
                                                                          competitionManager: objectGraph.competitionManager,
                                                                          subscriptionManager: objectGraph.subscriptionManager,
                                                                          homepageSheetViewModel: homepageSheetViewModel))
    }

    var body: some View {
        ZStack {
            Color("Bg").ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 6)

                Group {
                    switch viewModel.currentStep {
                    case .templates:
                        CreateTemplatesStep(viewModel: viewModel)
                    case .scoring:
                        CreateScoringStep(viewModel: viewModel) { showingProUpgrade = true }
                    case .invite:
                        CreateInviteStep(viewModel: viewModel,
                                         homepageSheetViewModel: homepageSheetViewModel,
                                         objectGraph: objectGraph)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                        removal: .move(edge: .leading).combined(with: .opacity)))
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("createWizard")
        .presentationDragIndicator(.visible)
        .sheet(isPresented: $showingProUpgrade) {
            ProUpgradeView(subscriptionManager: subscriptionManager,
                           serverEnvironmentManager: serverEnvironmentManager)
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                viewModel.goBack()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color("Ink"))
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color("Surface")))
                    .overlay(Circle().strokeBorder(Color("Border"), lineWidth: 1))
            }
            .buttonStyle(.plain)

            Spacer()

            StepIndicator(currentStep: viewModel.currentStep)

            Spacer()

            // Right-side placeholder for symmetry
            Color.clear.frame(width: 36, height: 36)
        }
    }
}

// MARK: - Step indicator

private struct StepIndicator: View {
    let currentStep: CreateCompetitionViewModel.Step

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(i == currentStep.rawValue ? Color("Ink") : Color("InkFaint"))
                    .frame(width: 6, height: 6)
            }
            Text("\(currentStep.rawValue + 1) of 3")
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.4)
                .foregroundStyle(Color("InkMute"))
                .padding(.leading, 4)
        }
    }
}

// MARK: - Step 1: Templates

struct CreateTemplatesStep: View {
    @ObservedObject var viewModel: CreateCompetitionViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Start a competition")
                        .font(.system(size: 28, weight: .regular, design: .serif))
                        .foregroundStyle(Color("Ink"))
                    Text("Pick a template that fits your group — you can change anything in the next step.")
                        .font(.system(size: 14))
                        .foregroundStyle(Color("InkSoft"))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                VStack(spacing: 12) {
                    ForEach(CreateCompetitionViewModel.templates) { template in
                        TemplateCard(template: template) {
                            viewModel.applyTemplate(template)
                        }
                    }

                    FWFSecondaryButton("Start blank", icon: "square.and.pencil") {
                        viewModel.startBlank()
                    }
                    .accessibilityIdentifier("createWizardStartBlank")
                    .padding(.top, 4)

                    smartTip
                        .padding(.top, 8)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
    }

    private var smartTip: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "lightbulb.fill")
                .foregroundStyle(Color("Brand"))
                .font(.system(size: 14))
            Text("Most groups pick a 7-day rings comp first — short enough to stay competitive, long enough to recover from a bad day.")
                .font(.system(size: 12))
                .foregroundStyle(Color("InkSoft"))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color("BrandSoft"))
        )
    }
}

private struct TemplateCard: View {
    let template: CreateCompetitionViewModel.Template
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color("BrandSoft"))
                    Image(systemName: template.icon)
                        .font(.system(size: 18))
                        .foregroundStyle(Color("Brand"))
                }
                .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(template.title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color("Ink"))
                        if let pill = template.pillText {
                            Text(pill)
                                .font(.system(size: 10, weight: .semibold))
                                .tracking(0.4)
                                .foregroundStyle(template.pillIsPro ? Color("Sun") : Color("Exercise"))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule().fill(
                                        (template.pillIsPro ? Color("Sun") : Color("Exercise")).opacity(0.18)
                                    )
                                )
                        }
                    }
                    Text(template.subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(Color("InkSoft"))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color("InkMute"))
                    .padding(.top, 8)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color("Surface"))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Color("Border"), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Step 2: Scoring

struct CreateScoringStep: View {
    @ObservedObject var viewModel: CreateCompetitionViewModel
    let onShowProUpgrade: () -> Void
    @State private var showingActivityPicker = false
    @FocusState private var nameFieldFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 14) {
                    if viewModel.state.isFailed {
                        FWFErrorBanner(message: viewModel.state.errorMessage)
                    }

                    livePreview
                        .padding(.horizontal, 16)

                    nameAndDateCard
                        .padding(.horizontal, 16)

                    modeSegmentedControl
                        .padding(.horizontal, 16)

                    Group {
                        switch viewModel.ruleKind {
                        case .rings:    ringsConfig
                        case .daily:    dailyConfig
                        case .workouts: workoutsConfig
                        }
                    }
                    .padding(.horizontal, 16)

                    if viewModel.requiresProUserMissing {
                        proCallout
                            .padding(.horizontal, 16)
                    }

                    Spacer().frame(height: 12)
                }
                .padding(.top, 8)
                .padding(.bottom, 100)
            }

            // Floating submit
            VStack(spacing: 0) {
                Divider().background(Color("Border"))
                submitButton
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color("Bg"))
            }
        }
        .sheet(isPresented: $showingActivityPicker) {
            ActivityTypePickerView(selected: $viewModel.selectedActivityTypes)
        }
    }

    // MARK: Step 2 — building blocks

    private var livePreview: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Live preview")
                .font(.system(size: 10.5, weight: .semibold))
                .tracking(0.6)
                .foregroundStyle(.white.opacity(0.7))
            Text(viewModel.competitionName.isEmpty ? "Untitled competition" : viewModel.competitionName)
                .font(.system(size: 18, weight: .semibold, design: .serif))
                .foregroundStyle(.white)
                .lineLimit(2)
            Text(viewModel.buildRule().humanReadableDescription)
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(colors: [Color("Brand"), Color("BrandHi")],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var nameAndDateCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Name")
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(0.4)
                    .foregroundStyle(Color("InkMute"))
                TextField("e.g., January Challenge", text: $viewModel.competitionName)
                    .textFieldStyle(.roundedBorder)
                    .submitLabel(.done)
                    .focused($nameFieldFocused)
                    .onSubmit { nameFieldFocused = false }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Dates")
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(0.4)
                    .foregroundStyle(Color("InkMute"))
                DatePicker("Starts", selection: $viewModel.startDate,
                           in: Date()..., displayedComponents: .date)
                DatePicker("Ends", selection: $viewModel.endDate,
                           in: viewModel.startDate.addingTimeInterval(.xtDays(1))...viewModel.startDate.addingTimeInterval(.xtDays(30)),
                           displayedComponents: .date)
            }
        }
        .fwfCard(padding: 14)
    }

    private var modeSegmentedControl: some View {
        HStack(spacing: 4) {
            modeSegment(.rings, label: "Rings", isPro: false)
            modeSegment(.daily, label: "Daily", isPro: true)
            modeSegment(.workouts, label: "Workouts", isPro: true)
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color("SurfaceAlt"))
        )
    }

    private func modeSegment(_ kind: ScoringRules.Kind, label: String, isPro: Bool) -> some View {
        let selected = viewModel.ruleKind == kind
        return Button {
            withAnimation(.spring(duration: 0.25)) {
                viewModel.ruleKind = kind
            }
        } label: {
            HStack(spacing: 4) {
                Text(label)
                    .font(.system(size: 13, weight: .semibold))
                if isPro && !selected {
                    Text("PRO")
                        .font(.system(size: 8, weight: .bold))
                        .tracking(0.5)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Capsule().fill(Color("Sun").opacity(0.2)))
                        .foregroundStyle(Color("Sun"))
                }
            }
            .foregroundStyle(selected ? Color("Bg") : Color("Ink"))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(selected ? Color("Ink") : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("scoringMode_\(label)")
    }

    // Rings mode

    private var ringsConfig: some View {
        VStack(spacing: 14) {
            // Visual ring picker
            VStack(alignment: .leading, spacing: 10) {
                Text("Which rings count?")
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(0.4)
                    .foregroundStyle(Color("InkMute"))

                HStack(spacing: 10) {
                    ringPickerCard(name: "Move", goal: "500 cal", color: Color("Move"), isOn: $viewModel.includeCalories)
                    ringPickerCard(name: "Exercise", goal: "30 min", color: Color("Exercise"), isOn: $viewModel.includeExercise)
                    ringPickerCard(name: "Stand", goal: "12 hr", color: Color("Stand"), isOn: $viewModel.includeStand)
                }

                if viewModel.includedRingCount > 0 {
                    Text("\(viewModel.includedRingCount) of 3 rings selected · 200 pts max per day per ring")
                        .font(.system(size: 11))
                        .foregroundStyle(Color("InkMute"))
                } else {
                    Text("Select at least one ring")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color("Move"))
                }
            }
            .fwfCard(padding: 14)

            minimumGoalsCard
            dailyCapCard
        }
    }

    private func ringPickerCard(name: String, goal: String, color: Color, isOn: Binding<Bool>) -> some View {
        Button {
            isOn.wrappedValue.toggle()
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .strokeBorder(color.opacity(0.25), lineWidth: 5)
                    Circle()
                        .trim(from: 0, to: 0.75)
                        .stroke(color, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }
                .frame(width: 44, height: 44)
                Text(name)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color("Ink"))
                Text(goal)
                    .font(.system(size: 10))
                    .foregroundStyle(Color("InkMute"))
                Image(systemName: isOn.wrappedValue ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 14))
                    .foregroundStyle(isOn.wrappedValue ? color : Color("InkFaint"))
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isOn.wrappedValue ? Color("Surface") : Color("SurfaceAlt"))
            )
            .opacity(isOn.wrappedValue ? 1.0 : 0.55)
        }
        .buttonStyle(.plain)
    }

    private var minimumGoalsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Set a minimum goal floor")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color("Ink"))
                    Text("Players with personal goals below the floor are scored as if their goal matched it. Higher personal goals are used as-is. Prevents a low Move goal from being an easy win.")
                        .font(.system(size: 11))
                        .foregroundStyle(Color("InkSoft"))
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                Toggle("", isOn: $viewModel.enforceMinGoals)
                    .labelsHidden()
            }

            if viewModel.enforceMinGoals {
                presetChipRow

                if viewModel.includeCalories {
                    floorSlider(label: "Move floor",
                                value: Binding(get: { Double(viewModel.minCalories) },
                                               set: { viewModel.minCalories = Int($0) }),
                                range: 100...1200,
                                unit: "cal")
                }
                if viewModel.includeExercise {
                    floorSlider(label: "Exercise floor",
                                value: Binding(get: { Double(viewModel.minExercise) },
                                               set: { viewModel.minExercise = Int($0) }),
                                range: 10...60,
                                unit: "min")
                }
            }
        }
        .fwfCard(padding: 14)
    }

    private var presetChipRow: some View {
        HStack(spacing: 6) {
            presetChip("Casual",  cal: 300, ex: 20, st: 8)
            presetChip("Active",  cal: 500, ex: 30, st: 12)
            presetChip("Athlete", cal: 750, ex: 45, st: 12)
        }
    }

    private func presetChip(_ label: String, cal: Int, ex: Int, st: Int) -> some View {
        Button {
            viewModel.minCalories = cal
            viewModel.minExercise = ex
            viewModel.minStand = st
        } label: {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color("Brand"))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Capsule().fill(Color("BrandSoft")))
        }
        .buttonStyle(.plain)
    }

    private func floorSlider(label: String, value: Binding<Double>, range: ClosedRange<Double>, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.system(size: 12))
                    .foregroundStyle(Color("InkSoft"))
                Spacer()
                Text("\(Int(value.wrappedValue)) \(unit)")
                    .font(.system(size: 12, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(Color("Ink"))
            }
            Slider(value: value, in: range, step: 1)
                .tint(Color("Brand"))
        }
    }

    private var dailyCapCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Daily cap")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color("Ink"))
                    Text("Limit points earned per day so an outlier session doesn't decide the whole competition.")
                        .font(.system(size: 11))
                        .foregroundStyle(Color("InkSoft"))
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                Toggle("", isOn: $viewModel.dailyCapEnabled)
                    .labelsHidden()
            }

            if viewModel.dailyCapEnabled {
                HStack {
                    Text("Cap value")
                        .font(.system(size: 12))
                        .foregroundStyle(Color("InkSoft"))
                    Spacer()
                    Stepper(value: $viewModel.dailyCap, in: 100...1200, step: 50) {
                        Text("\(viewModel.dailyCap) pts")
                            .font(.system(size: 12, weight: .semibold))
                            .monospacedDigit()
                    }
                }
            }
        }
        .fwfCard(padding: 14)
    }

    // Daily mode

    private var dailyConfig: some View {
        VStack(spacing: 14) {
            HStack(spacing: 10) {
                metricBigCard("Steps",    icon: "shoeprints.fill", selected: viewModel.dailyMetric == .steps) {
                    viewModel.dailyMetric = .steps
                }
                metricBigCard("Distance", icon: "map.fill",        selected: viewModel.dailyMetric == .walkingRunningDistance) {
                    viewModel.dailyMetric = .walkingRunningDistance
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("How it works")
                    .font(.system(size: 14, weight: .semibold))
                Text("Each day, points are added up. Highest total at the end wins.")
                    .font(.system(size: 12))
                    .foregroundStyle(Color("InkSoft"))
            }
            .fwfCard(padding: 14)
        }
    }

    private func metricBigCard(_ label: String, icon: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(selected ? Color("Bg") : Color("Brand"))
                Text(label)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(selected ? Color("Bg") : Color("Ink"))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(selected ? Color("Ink") : Color("Surface"))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color("Border"), lineWidth: selected ? 0 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    // Workouts mode

    private var workoutsConfig: some View {
        VStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Metric")
                    .font(.system(size: 14, weight: .semibold))
                HStack(spacing: 6) {
                    workoutMetricChip("Calories", .calories)
                    workoutMetricChip("Minutes", .duration)
                    workoutMetricChip("Distance", .distance)
                }
            }
            .fwfCard(padding: 14)

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Workout types")
                        .font(.system(size: 14, weight: .semibold))
                    Spacer()
                    Text(viewModel.selectedActivityTypes.isEmpty ? "Any" : "\(viewModel.selectedActivityTypes.count) selected")
                        .font(.system(size: 12))
                        .foregroundStyle(Color("InkMute"))
                }

                FlowLayout(spacing: 6) {
                    ForEach(Array(viewModel.selectedActivityTypes).sorted(), id: \.self) { raw in
                        Text(WorkoutActivityTypeCatalog.displayName(for: raw) ?? "")
                            .font(.system(size: 12, weight: .medium))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color("BrandSoft")))
                            .foregroundStyle(Color("Brand"))
                    }
                    Button {
                        showingActivityPicker = true
                    } label: {
                        Label("Add more", systemImage: "plus")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color("Ink"))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Capsule().stroke(Color("Border"), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("workoutTypesPickerButton")
                    .accessibilityLabel("Workout types")
                }
            }
            .fwfCard(padding: 14)

            VStack(alignment: .leading, spacing: 10) {
                Text("Minimum duration")
                    .font(.system(size: 14, weight: .semibold))
                HStack(spacing: 6) {
                    ForEach([5, 10, 15, 20], id: \.self) { mins in
                        durationChip(mins)
                    }
                }
            }
            .fwfCard(padding: 14)
        }
    }

    private func workoutMetricChip(_ label: String, _ metric: WorkoutMetric) -> some View {
        let selected = viewModel.workoutMetric == metric
        return Button {
            viewModel.workoutMetric = metric
        } label: {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(selected ? Color("Bg") : Color("Ink"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(selected ? Color("Ink") : Color("SurfaceAlt"))
                )
        }
        .buttonStyle(.plain)
    }

    private func durationChip(_ mins: Int) -> some View {
        let selected = viewModel.workoutMinDurationMinutes == mins
        return Button {
            viewModel.workoutMinDurationMinutes = mins
        } label: {
            Text("\(mins) min")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(selected ? Color("Bg") : Color("Ink"))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule().fill(selected ? Color("Ink") : Color("SurfaceAlt"))
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Pro callout + submit

    private var proCallout: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: "lock.fill")
                    .foregroundStyle(Color("Sun"))
                Text("Pro features in use")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color("Ink"))
            }
            Text("Custom scoring rules and non-rings modes are part of FitWithFriends Pro ($2.99/month).")
                .font(.system(size: 12))
                .foregroundStyle(Color("InkSoft"))
            Button("See what Pro unlocks →") { onShowProUpgrade() }
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color("Brand"))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color("Sun").opacity(0.14))
        )
    }

    @ViewBuilder
    private var submitButton: some View {
        if viewModel.requiresProUserMissing {
            FWFPrimaryButton("Start Pro · $2.99/mo") { onShowProUpgrade() }
                .accessibilityIdentifier("createCompetitionProUpgradeButton")
                .accessibilityLabel("Upgrade to Pro")
        } else {
            FWFPrimaryButton(viewModel.state == .inProgress ? "Creating…" : "Create competition") {
                viewModel.createCompetition()
            }
            .accessibilityIdentifier("createCompetitionSubmitButton")
            .accessibilityLabel("Create")
            .disabled(!viewModel.canSubmit || viewModel.state == .inProgress)
            .opacity(viewModel.canSubmit ? 1.0 : 0.55)
        }
    }
}

// MARK: - Step 3: Invite

struct CreateInviteStep: View {
    @ObservedObject var viewModel: CreateCompetitionViewModel
    let homepageSheetViewModel: HomepageSheetViewModel
    let objectGraph: IObjectGraph

    @State private var shareUrl: URL?
    @State private var loadingShareUrl: Bool = true
    @State private var showingSystemShare: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                VStack(spacing: 10) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color("Exercise"))
                        FWFTag(text: "Competition created", color: Color("Exercise"))
                    }

                    FWFDisplay(
                        parts: [("Now invite some\n", false), ("worthy opponents.", true)],
                        size: 32,
                        italicColor: Color("Brand"),
                        alignment: .center
                    )
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)

                shareableCard
                    .padding(.horizontal, 16)

                actionRow
                    .padding(.horizontal, 16)

                footerTip
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
            }
        }
        .task {
            await loadShareUrl()
        }
        .sheet(isPresented: $showingSystemShare) {
            if let shareUrl {
                ShareSheet(url: shareUrl)
            }
        }
    }

    private var shareableCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.lastCreatedCompetitionName ?? viewModel.competitionName)
                .font(.system(size: 20, weight: .semibold, design: .serif))
                .foregroundStyle(.white)
                .lineLimit(2)
            Text(viewModel.buildRule().humanReadableDescription)
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)

            if let url = shareUrl {
                HStack(spacing: 8) {
                    Image(systemName: "link")
                        .font(.system(size: 11))
                    Text(url.absoluteString)
                        .font(.system(size: 11, design: .monospaced))
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .foregroundStyle(.white.opacity(0.9))
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(.white.opacity(0.15))
                )
                .padding(.top, 8)
            } else if loadingShareUrl {
                ProgressView()
                    .tint(.white)
                    .padding(.top, 8)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(colors: [Color("Brand"), Color("BrandHi")],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var actionRow: some View {
        VStack(spacing: 10) {
            FWFPrimaryButton("Share", icon: "square.and.arrow.up") {
                if shareUrl != nil { showingSystemShare = true }
            }
            .disabled(shareUrl == nil)
            .opacity(shareUrl == nil ? 0.55 : 1)

            HStack(spacing: 10) {
                FWFSecondaryButton("Copy link", icon: "doc.on.doc") {
                    if let url = shareUrl {
                        UIPasteboard.general.string = url.absoluteString
                    }
                }
                FWFSecondaryButton("Done", icon: "checkmark") {
                    homepageSheetViewModel.updateState(sheet: .createCompetition, state: false)
                }
            }
        }
    }

    private var footerTip: some View {
        Text("Friends without the app yet? They'll see a join page with your competition details and a link to download.")
            .font(.system(size: 12))
            .foregroundStyle(Color("InkSoft"))
            .multilineTextAlignment(.center)
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color("BrandSoft"))
            )
    }

    private func loadShareUrl() async {
        loadingShareUrl = true
        defer { loadingShareUrl = false }
        guard let name = viewModel.lastCreatedCompetitionName else { return }

        // Find the just-created competition by name + admin flag from the manager's overviews.
        let overviews = await firstOverviews()
        guard let match = overviews.values.first(where: { $0.isUserAdmin && $0.competitionName == name }) else { return }

        do {
            let admin = try await objectGraph.competitionManager.getCompetitionAdminDetail(for: match.competitionId)
            let url = JoinCompetitionProtocolData.createWebsiteUrl(
                serverBaseUrl: objectGraph.serverEnvironmentManager.baseUrl,
                competitionId: admin.competitionId,
                competitionToken: admin.competitionAccessToken
            )
            await MainActor.run { self.shareUrl = url }
        } catch {
            Logger.traceError(message: "Failed to load admin detail for new competition", error: error)
        }
    }

    /// One-shot read of the current value of the overviews publisher.
    private func firstOverviews() async -> [UUID: CompetitionOverview] {
        await withCheckedContinuation { continuation in
            var resumed = false
            let cancellable = objectGraph.competitionManager.competitionOverviewsPublisher
                .first()
                .sink { value in
                    if !resumed {
                        resumed = true
                        continuation.resume(returning: value)
                    }
                }
            // Drop reference once we resume.
            _ = cancellable
        }
    }
}

// MARK: - Activity Type Picker (categorized)

struct ActivityTypePickerView: View {
    @Binding var selected: Set<UInt>
    @Environment(\.dismiss) private var dismiss
    @State private var query: String = ""

    private var matchedEntries: [WorkoutActivityTypeCatalog.Entry] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if trimmed.isEmpty { return WorkoutActivityTypeCatalog.commonEntries }
        return WorkoutActivityTypeCatalog.commonEntries.filter { $0.displayName.lowercased().contains(trimmed) }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color("Bg").ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 14) {
                        // Search
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(Color("InkMute"))
                            TextField("Search activities", text: $query)
                                .autocorrectionDisabled()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color("SurfaceAlt"))
                        )
                        .padding(.horizontal, 16)

                        // Any workout toggle
                        Button {
                            selected.removeAll()
                        } label: {
                            HStack {
                                Text("Any workout type")
                                    .foregroundStyle(Color("Ink"))
                                Spacer()
                                if selected.isEmpty {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Color("Brand"))
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundStyle(Color("InkFaint"))
                                }
                            }
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color("Surface"))
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 16)

                        // Categorized groups
                        ForEach(WorkoutActivityTypeCatalog.Category.allCases) { category in
                            let entries = matchedEntries.filter { $0.category == category }
                            if !entries.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(category.displayName)
                                        .font(.system(size: 12, weight: .semibold))
                                        .tracking(0.4)
                                        .foregroundStyle(Color("InkMute"))
                                        .padding(.horizontal, 20)

                                    VStack(spacing: 0) {
                                        ForEach(entries) { entry in
                                            entryRow(entry)
                                            if entry.id != entries.last?.id {
                                                Divider().background(Color("Border"))
                                            }
                                        }
                                    }
                                    .background(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .fill(Color("Surface"))
                                    )
                                    .padding(.horizontal, 16)
                                }
                            }
                        }

                        Spacer().frame(height: 24)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Workout types")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func entryRow(_ entry: WorkoutActivityTypeCatalog.Entry) -> some View {
        Button {
            if selected.contains(entry.rawValue) {
                selected.remove(entry.rawValue)
            } else {
                selected.insert(entry.rawValue)
            }
        } label: {
            HStack {
                Text(entry.displayName)
                    .foregroundStyle(Color("Ink"))
                Spacer()
                if selected.contains(entry.rawValue) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color("Brand"))
                } else {
                    Image(systemName: "circle")
                        .foregroundStyle(Color("InkFaint"))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Simple flow layout used for workout-type pills

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard let maxWidth = proposal.width else {
            let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
            let width = sizes.map(\.width).reduce(0, +) + spacing * CGFloat(max(0, subviews.count - 1))
            let height = sizes.map(\.height).max() ?? 0
            return CGSize(width: width, height: height)
        }

        var lineWidth: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if lineWidth + size.width > maxWidth {
                totalHeight += lineHeight + spacing
                lineWidth = size.width + spacing
                lineHeight = size.height
            } else {
                lineWidth += size.width + spacing
                lineHeight = max(lineHeight, size.height)
            }
        }
        totalHeight += lineHeight
        return CGSize(width: maxWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x: CGFloat = bounds.minX
        var y: CGFloat = bounds.minY
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX {
                x = bounds.minX
                y += lineHeight + spacing
                lineHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}

// MARK: - Previews

struct CreateCompetitionView_Previews: PreviewProvider {
    static var previews: some View {
        CreateCompetitionView(homepageSheetViewModel: HomepageSheetViewModel(appProtocolHandler: MockAppProtocolHandler(),
                                                                             healthKitManager: MockHealthKitManager()),
                              objectGraph: MockObjectGraph())
    }
}
