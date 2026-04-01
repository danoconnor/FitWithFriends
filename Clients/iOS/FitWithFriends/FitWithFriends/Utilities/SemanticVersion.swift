//
//  SemanticVersion.swift
//  FitWithFriends
//

import Foundation

/// Compares two dot-separated version strings by splitting on "." and comparing
/// each component as an integer. Handles versions with different component counts
/// by treating missing components as 0 (e.g. "1.0" == "1.0.0").
///
/// Returns .orderedAscending if lhs < rhs, .orderedSame if equal, .orderedDescending if lhs > rhs.
func compareSemanticVersions(_ lhs: String, _ rhs: String) -> ComparisonResult {
    let lhsComponents = lhs.split(separator: ".").compactMap { Int($0) }
    let rhsComponents = rhs.split(separator: ".").compactMap { Int($0) }
    let maxCount = max(lhsComponents.count, rhsComponents.count)

    for i in 0 ..< maxCount {
        let l = i < lhsComponents.count ? lhsComponents[i] : 0
        let r = i < rhsComponents.count ? rhsComponents[i] : 0
        if l < r { return .orderedAscending }
        if l > r { return .orderedDescending }
    }
    return .orderedSame
}
