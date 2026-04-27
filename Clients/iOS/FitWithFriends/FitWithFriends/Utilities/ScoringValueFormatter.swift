//
//  ScoringValueFormatter.swift
//  FitWithFriends
//
//  Formats numeric scores for display using the unit the competition's scoring rule expects.
//  Distance ('meters') is localised to miles or kilometres based on the user's locale.
//

import Foundation

public enum ScoringValueFormatter {

    /// Format a value for compact leaderboard display (no unit suffix when space is tight).
    public static func formatCompact(_ value: Double, unit: ScoringUnit) -> String {
        return format(value, unit: unit, compact: true)
    }

    /// Format a value with its unit for detail / descriptive contexts.
    public static func format(_ value: Double, unit: ScoringUnit, compact: Bool = false) -> String {
        switch unit {
        case .points:
            return compact ? "\(formatInt(value))" : "\(formatInt(value)) pts"
        case .steps:
            return "\(formatThousands(value))\(compact ? "" : " steps")"
        case .kcal:
            return "\(formatInt(value))\(compact ? "" : " kcal")"
        case .minutes:
            return "\(formatInt(value))\(compact ? "" : " min")"
        case .meters:
            return formatDistance(meters: value, compact: compact)
        }
    }

    private static func formatInt(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 0
        formatter.groupingSeparator = ","
        formatter.usesGroupingSeparator = true
        return formatter.string(from: NSNumber(value: value)) ?? "\(Int(value))"
    }

    private static func formatThousands(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 0
        formatter.groupingSeparator = ","
        formatter.usesGroupingSeparator = true
        return formatter.string(from: NSNumber(value: value)) ?? "\(Int(value))"
    }

    private static func formatDistance(meters: Double, compact: Bool) -> String {
        let usesImperial = Locale.current.measurementSystem != .metric
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 1

        if usesImperial {
            let miles = meters / 1609.344
            let number = formatter.string(from: NSNumber(value: miles)) ?? String(format: "%.2f", miles)
            return compact ? number : "\(number) mi"
        } else {
            let kilometres = meters / 1000.0
            let number = formatter.string(from: NSNumber(value: kilometres)) ?? String(format: "%.2f", kilometres)
            return compact ? number : "\(number) km"
        }
    }
}
