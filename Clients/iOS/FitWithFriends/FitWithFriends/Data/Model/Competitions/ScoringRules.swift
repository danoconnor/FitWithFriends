//
//  ScoringRules.swift
//  FitWithFriends
//
//  Per-competition scoring rule configuration. The shape must match
//  `ScoringRules` in WebService/FitWithFriends/utilities/competitionStandingsHelper.ts.
//

import Foundation

public enum ScoringRing: String, Codable, CaseIterable, Hashable {
    case calories
    case exercise
    case stand
}

public enum WorkoutMetric: String, Codable, CaseIterable, Hashable {
    case calories
    case duration
    case distance
}

public enum DailyMetric: String, Codable, CaseIterable, Hashable {
    case steps
    case walkingRunningDistance
}

public struct RingMinGoals: Codable, Hashable {
    public var calories: Int?
    public var exerciseTime: Int?
    public var standTime: Int?

    public init(calories: Int? = nil, exerciseTime: Int? = nil, standTime: Int? = nil) {
        self.calories = calories
        self.exerciseTime = exerciseTime
        self.standTime = standTime
    }

    public var isEmpty: Bool { calories == nil && exerciseTime == nil && standTime == nil }
}

/// Discriminated union matching the server's `ScoringRules`. Round-trips through JSON
/// with a `kind` discriminator. `.default` is the legacy activity-rings rule (`nil` on the wire).
public enum ScoringRules: Codable, Hashable {
    case rings(includedRings: Set<ScoringRing>, minGoals: RingMinGoals?, dailyCap: Int?)
    case workouts(metric: WorkoutMetric, activityTypes: [UInt]?)
    case daily(metric: DailyMetric)

    public static let `default`: ScoringRules = .rings(
        includedRings: Set(ScoringRing.allCases),
        minGoals: nil,
        dailyCap: nil
    )

    public enum Kind: String, Codable {
        case rings
        case workouts
        case daily
    }

    public var kind: Kind {
        switch self {
        case .rings: return .rings
        case .workouts: return .workouts
        case .daily: return .daily
        }
    }

    public var isDefault: Bool {
        if case let .rings(includedRings, minGoals, dailyCap) = self {
            return includedRings == Set(ScoringRing.allCases) && minGoals == nil && dailyCap == nil
        }
        return false
    }

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case kind
        case includedRings
        case minGoals
        case dailyCap
        case metric
        case activityTypes
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(Kind.self, forKey: .kind)
        switch kind {
        case .rings:
            let rings = try container.decodeIfPresent([ScoringRing].self, forKey: .includedRings)
            let included: Set<ScoringRing> = {
                if let rings, !rings.isEmpty { return Set(rings) }
                return Set(ScoringRing.allCases)
            }()
            let minGoals = try container.decodeIfPresent(RingMinGoals.self, forKey: .minGoals)
            let dailyCap = try container.decodeIfPresent(Int.self, forKey: .dailyCap)
            self = .rings(includedRings: included, minGoals: minGoals, dailyCap: dailyCap)
        case .workouts:
            let metric = try container.decode(WorkoutMetric.self, forKey: .metric)
            let activityTypes = try container.decodeIfPresent([UInt].self, forKey: .activityTypes)
            self = .workouts(metric: metric, activityTypes: activityTypes)
        case .daily:
            let metric = try container.decode(DailyMetric.self, forKey: .metric)
            self = .daily(metric: metric)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(kind, forKey: .kind)
        switch self {
        case let .rings(includedRings, minGoals, dailyCap):
            let orderedRings = ScoringRing.allCases.filter { includedRings.contains($0) }
            try container.encode(orderedRings, forKey: .includedRings)
            if let minGoals, !minGoals.isEmpty {
                try container.encode(minGoals, forKey: .minGoals)
            }
            if let dailyCap { try container.encode(dailyCap, forKey: .dailyCap) }
        case let .workouts(metric, activityTypes):
            try container.encode(metric, forKey: .metric)
            if let activityTypes, !activityTypes.isEmpty {
                try container.encode(activityTypes, forKey: .activityTypes)
            }
        case let .daily(metric):
            try container.encode(metric, forKey: .metric)
        }
    }
}

// MARK: - Display helpers

public enum ScoringUnit: String, Codable {
    case points
    case kcal
    case minutes
    case meters
    case steps

    /// Default unit derived from the rule when the server doesn't supply one.
    public static func derive(from rules: ScoringRules) -> ScoringUnit {
        switch rules {
        case .rings: return .points
        case let .workouts(metric, _):
            switch metric {
            case .calories: return .kcal
            case .duration: return .minutes
            case .distance: return .meters
            }
        case let .daily(metric):
            return metric == .steps ? .steps : .meters
        }
    }
}

public extension ScoringRules {
    /// One-line human-readable summary for the "How scoring works" row on the competition overview.
    var humanReadableDescription: String {
        switch self {
        case let .rings(includedRings, minGoals, dailyCap):
            let names = ScoringRing.allCases
                .filter { includedRings.contains($0) }
                .map(\.displayName)
            let base: String
            if names.count == ScoringRing.allCases.count {
                base = "Earn 1 point for every percent of each Apple activity ring you close"
            } else if names.count == 1 {
                base = "Earn 1 point for every percent of your \(names[0]) ring you close"
            } else {
                let list = names.joined(separator: ", ")
                base = "Earn 1 point for every percent of your \(list) rings you close"
            }

            var parts: [String] = [base]
            if let minGoals, !minGoals.isEmpty {
                var bits: [String] = []
                if let calories = minGoals.calories { bits.append("\(calories) cal") }
                if let exercise = minGoals.exerciseTime { bits.append("\(exercise) min exercise") }
                if let stand = minGoals.standTime { bits.append("\(stand) stand hr") }
                parts.append("Minimum goals enforced: " + bits.joined(separator: ", "))
            }
            if let dailyCap {
                parts.append("Daily cap: \(dailyCap) points")
            }
            return parts.joined(separator: ". ") + "."

        case let .workouts(metric, activityTypes):
            let metricLabel: String
            switch metric {
            case .calories: metricLabel = "calories burned"
            case .duration: metricLabel = "minutes of workout time"
            case .distance: metricLabel = "distance"
            }
            if let activityTypes, !activityTypes.isEmpty {
                let list = activityTypes
                    .compactMap { WorkoutActivityTypeCatalog.displayName(for: $0) }
                    .joined(separator: ", ")
                return "Score \(metricLabel) from \(list) workouts only."
            }
            return "Score \(metricLabel) from any tracked workout."

        case let .daily(metric):
            switch metric {
            case .steps: return "Score your daily step count."
            case .walkingRunningDistance: return "Score your daily walking and running distance."
            }
        }
    }
}

public extension ScoringRing {
    var displayName: String {
        switch self {
        case .calories: return "Move"
        case .exercise: return "Exercise"
        case .stand: return "Stand"
        }
    }
}
