//
//  UserCompetitionPoints.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 8/13/25.
//


public class UserCompetitionPoints: IdentifiableBase, Codable, Comparable {
    enum CodingKeys: String, CodingKey {
        case userId
        case firstName
        case lastName
        case totalPoints = "activityPoints"
        case pointsToday
    }

    let userId: String
    let firstName: String
    let lastName: String
    let totalPoints: Double?
    let pointsToday: Double?

    var displayName: String {
        firstName + " " + lastName
    }

    /// This init is used for testing and mock data. Production code will decode the entity from JSON
    public init(userId: String = "user_id", firstName: String = "Test", lastName: String = "User", total: Double = 0, today: Double = 0) {
        self.userId = userId
        self.firstName = firstName
        self.lastName = lastName
        totalPoints = total
        pointsToday = today
    }

    public static func == (lhs: UserCompetitionPoints, rhs: UserCompetitionPoints) -> Bool {
        return lhs.userId == rhs.userId
    }

    public static func < (lhs: UserCompetitionPoints, rhs: UserCompetitionPoints) -> Bool {
        let lhsPoints = lhs.totalPoints ?? 0
        let rhsPoints = rhs.totalPoints ?? 0

        // If one or both sides have points, order by highest points first
        if lhs.totalPoints != nil || rhs.totalPoints != nil {
            if lhsPoints != rhsPoints {
                return lhsPoints > rhsPoints
            }

            // If total points are equal, use points today as a tiebreaker
            if lhs.pointsToday != rhs.pointsToday {
                return (lhs.pointsToday ?? 0) > (rhs.pointsToday ?? 0)
            }
        }

        // Default to ordering by name if there are no points,
        // or the total points and points today are both equal
        return lhs.displayName > rhs.displayName
    }
}
