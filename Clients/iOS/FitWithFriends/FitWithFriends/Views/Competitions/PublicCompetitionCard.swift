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
                    .foregroundStyle(Color("FwFBrandingColor"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color("FwFBrandingColor").opacity(0.12))
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
                            .fill(Color("FwFBrandingColor").opacity(0.12))
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

            Divider()

            // Action row
            if competition.isUserMember {
                Label("You've joined", systemImage: "checkmark.circle.fill")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color("FwFBrandingColor"))
            } else if isUserPro {
                Button(action: onJoin) {
                    Text("Join Competition")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color("FwFBrandingColor"))
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
                                .fill(Color("FwFBrandingColor"))
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}
