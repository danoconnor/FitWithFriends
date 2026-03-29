//
//  FWFStyles.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 3/26/26.
//

import SwiftUI

// MARK: - Card Modifier

struct FWFCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
            )
    }
}

extension View {
    func fwfCard() -> some View {
        modifier(FWFCardModifier())
    }
}

// MARK: - Error Banner

struct FWFErrorBanner: View {
    let message: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.primary)

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.red.opacity(0.12))
        )
        .padding(.horizontal, 16)
    }
}

// MARK: - Primary Button

struct FWFPrimaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void

    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Group {
                if let icon {
                    Label(title, systemImage: icon)
                } else {
                    Text(title)
                }
            }
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color("FwFBrandingColor"))
            )
        }
    }
}

// MARK: - Feature Row (for onboarding screens)

struct FWFFeatureRow: View {
    let icon: String
    let color: Color
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(color)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Previews

#Preview("Card Modifier") {
    VStack {
        Text("Card content here")
            .frame(maxWidth: .infinity)
            .fwfCard()
            .padding(.horizontal, 16)
    }
}

#Preview("Error Banner") {
    FWFErrorBanner(message: "Something went wrong. Please try again.")
}

#Preview("Primary Button") {
    FWFPrimaryButton("Create Competition", icon: "plus.circle.fill") { }
        .padding(.horizontal, 16)
}

#Preview("Feature Row") {
    FWFFeatureRow(icon: "figure.run",
                  color: .red,
                  title: "Compete with Friends",
                  description: "Earn points by closing your Apple activity rings each day.")
        .padding()
}
