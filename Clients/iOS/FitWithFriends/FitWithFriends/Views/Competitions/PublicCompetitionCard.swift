//
//  PublicCompetitionCard.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 3/30/26.
//

import SwiftUI

struct PublicCompetitionCard: View {
    let competition: PublicCompetition
    let isUserPro: Bool
    let onJoin: () -> Void
    let onUpgrade: () -> Void
    /// Invoked when the card body is tapped to preview the competition details
    /// (scoring rules + live leaderboard) before joining.
    let onSelect: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: title + public badge
            HStack(alignment: .top) {
                Text(competition.displayName)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)

                Spacer()

                Label("Public", systemImage: "globe")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color("Brand"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color("Brand").opacity(0.12))
                    )
            }

            // Metadata: member count + end date
            HStack(spacing: 10) {
                Text("\(competition.memberCount) members")
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color("Brand").opacity(0.12))
                    )

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption)
                    Text(competition.endDate.formatted(.dateTime.month().day()))
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }

            // Tappable affordance to preview the competition before joining
            HStack(spacing: 4) {
                Text("View leaderboard & scoring")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color("Brand"))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color("Brand"))
            }

            Divider()

            // Action row
            if competition.isUserMember {
                Label("You've joined", systemImage: "checkmark.circle.fill")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color("Brand"))
            } else if isUserPro {
                Button(action: onJoin) {
                    Text("Join Competition")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color("Brand"))
                        )
                }
                .buttonStyle(.plain)
            } else {
                Button(action: onUpgrade) {
                    Label("Upgrade to Pro", systemImage: "star.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color("Brand"))
                        )
                }
                .buttonStyle(.plain)
            }
        }
        // The inner Join / Upgrade buttons handle their own taps; tapping anywhere
        // else on the card opens the details preview.
        .contentShape(Rectangle())
        .onTapGesture { onSelect() }
        .accessibilityIdentifier("publicCompetitionCard")
    }
}
