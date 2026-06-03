//
//  SettingsView.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 4/23/22.
//
//  Replaces the stock `List(.insetGrouped)` with a chassis matching the rest of
//  the redesigned app: title block, account header, Pro upsell (free only),
//  custom card-style sections, and a footer. Both light and dark mode are
//  driven by the named colors in `Resources/Colors.xcassets`.
//

import SwiftUI

struct SettingsView: View {
    let emailUtility: IEmailUtility
    let serverEnvironmentManager: IServerEnvironmentManager
    let subscriptionManager: ISubscriptionManager

    /// Display name shown in the account header. The User model is a stub today,
    /// so the parent screen computes this from whatever data is available (the
    /// authenticated user's first name pulled off their competition roster).
    /// Nil is rendered as a tasteful fallback.
    let displayName: String?

    /// One-line subtitle under the display name. e.g. "Member since Apr 2023 ·
    /// Signed in with Apple". The brief allows "Signed in with Apple" alone when
    /// no member-since date is available.
    let memberSinceLabel: String

    let onDeleteAccount: () async -> Bool
    let onSignOut: () -> Void

    @State private var showDeleteAccountAlert = false
    @State private var showDeleteAccountErrorAlert = false
    @State private var isRestoringPurchases = false
    @State private var showRestoreSuccessAlert = false
    @State private var showRestoreErrorAlert = false
    @State private var showProUpgrade = false
    @Environment(\.dismiss) private var dismiss

    private var isUserPro: Bool { subscriptionManager.isUserPro }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    titleBlock
                    accountHeader
                    if !isUserPro { proUpsell }

                    helpSection
                    subscriptionSection
                    moreSection
                    accountSection
                    footer
                }
                .padding(.bottom, 28)
            }
            .background(Color("Bg"))
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color("Brand"))
                        .fontWeight(.semibold)
                        .accessibilityIdentifier("SettingsDoneButton")
                }
            }
        }
        .presentationDragIndicator(.visible)
        .sheet(isPresented: $showProUpgrade) {
            ProUpgradeView(subscriptionManager: subscriptionManager,
                           serverEnvironmentManager: serverEnvironmentManager)
        }
        .alert("Delete Account", isPresented: $showDeleteAccountAlert) {
            Button("Delete", role: .destructive) {
                Task {
                    let success = await onDeleteAccount()
                    if !success { showDeleteAccountErrorAlert = true }
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently delete your account and all your data. This cannot be undone.")
        }
        .alert("Error", isPresented: $showDeleteAccountErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Failed to delete your account. Please try again later.")
        }
        .alert("Purchases Restored", isPresented: $showRestoreSuccessAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your subscription has been restored.")
        }
        .alert("Restore Failed", isPresented: $showRestoreErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Failed to restore purchases. Please try again.")
        }
    }

    // MARK: - Sections

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            FWFTag(text: "Account & app")
            Text("Settings")
                .font(.system(size: 40, weight: .regular, design: .serif))
                .tracking(-0.8)
                .foregroundStyle(Color("Ink"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 22)
        .padding(.top, 14)
    }

    private var accountHeader: some View {
        HStack(spacing: 14) {
            FWFAvatar(name: displayName ?? "FitWithFriends User",
                      size: 56,
                      ring: isUserPro ? Color("Sun") : Color("Brand"))
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(displayName ?? "Welcome")
                        .font(.system(size: 17, weight: .bold))
                        .tracking(-0.3)
                        .foregroundStyle(Color("Ink"))
                    proBadge
                }
                Text(memberSinceLabel)
                    .font(.system(size: 12.5))
                    .foregroundStyle(Color("InkMute"))
            }
            Spacer(minLength: 0)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color("Surface"))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Color("Border"), lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .padding(.top, 20)
    }

    @ViewBuilder private var proBadge: some View {
        if isUserPro {
            Text("PRO")
                .font(.system(size: 9.5, weight: .bold))
                .tracking(0.8)
                .padding(.horizontal, 7)
                .padding(.vertical, 2)
                .background(Capsule().fill(Color("Sun").opacity(0.18)))
                .foregroundStyle(Color("Sun"))
        } else {
            Text("FREE")
                .font(.system(size: 9.5, weight: .bold))
                .tracking(0.8)
                .padding(.horizontal, 7)
                .padding(.vertical, 2)
                .background(Capsule().fill(Color("SurfaceAlt")))
                .foregroundStyle(Color("InkSoft"))
        }
    }

    private var proUpsell: some View {
        Button { showProUpgrade = true } label: {
            VStack(alignment: .leading, spacing: 8) {
                FWFTag(text: "Upgrade", color: .white.opacity(0.75))
                // "Make this *actually* competitive."
                (
                    Text("Make this ") +
                    Text("actually").italic().foregroundColor(Color("Sun")) +
                    Text(" competitive.")
                )
                .font(.system(size: 24, weight: .regular, design: .serif))
                .tracking(-0.5)
                .foregroundStyle(.white)

                Text("Up to 10 simultaneous competitions, custom scoring, public leaderboards. $2.99/mo.")
                    .font(.system(size: 12.5))
                    .foregroundStyle(.white.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 6) {
                    Text("Go Pro")
                    Image(systemName: "chevron.right").font(.caption)
                }
                .font(.system(size: 13, weight: .semibold))
                // BgDeep inverts with the gradient brand→brandHi pill below, in
                // both modes — near-white in light, near-black in dark.
                .foregroundStyle(Color("BgDeep"))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Capsule().fill(Color("Bg")))
                .padding(.top, 6)
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(
                    colors: [Color("Brand"), Color("BrandHi")],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("SettingsProUpsellButton")
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    private var helpSection: some View {
        SettingsSection(title: "Help") {
            NavigationLink {
                AboutCompetitionsView()
            } label: {
                SettingsRow(icon: "trophy", label: "How do competitions work?", kind: .nav)
            }
            .buttonStyle(.plain)

            SettingsDivider()

            NavigationLink {
                AboutHealthDataView()
            } label: {
                SettingsRow(icon: "heart.text.square", label: "Activity data troubleshooting", kind: .nav)
            }
            .buttonStyle(.plain)
        }
    }

    private var subscriptionSection: some View {
        SettingsSection(title: "Subscription") {
            if isUserPro {
                Link(destination: URL(string: "itms-apps://apps.apple.com/account/subscriptions")!) {
                    SettingsRow(
                        icon: "star",
                        label: "Manage subscription",
                        sub: "Opens iOS Settings",
                        kind: .ext
                    )
                }
                .buttonStyle(.plain)

                SettingsDivider()
            }

            Button {
                Task { await restorePurchases() }
            } label: {
                SettingsRow(
                    icon: "arrow.clockwise",
                    label: "Restore Purchases",
                    kind: .action,
                    loading: isRestoringPurchases
                )
            }
            .buttonStyle(.plain)
            .disabled(isRestoringPurchases)
            .accessibilityIdentifier("RestorePurchasesButton")
        }
    }

    private var moreSection: some View {
        SettingsSection(title: "More") {
            Button {
                emailUtility.sendLogEmail()
            } label: {
                SettingsRow(
                    icon: "envelope",
                    label: "Send diagnostic logs",
                    sub: "Helps us fix bugs faster",
                    kind: .action
                )
            }
            .buttonStyle(.plain)

            SettingsDivider()

            Link(destination: URL(string: "\(serverEnvironmentManager.baseUrl)/privacyPolicy")!) {
                SettingsRow(
                    icon: "hand.raised",
                    label: "Privacy policy",
                    kind: .ext
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var accountSection: some View {
        SettingsSection(title: "Account") {
            Button {
                onSignOut()
            } label: {
                SettingsRow(
                    icon: "arrow.left.square",
                    label: "Sign out",
                    kind: .action
                )
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("SettingsSignOutButton")

            SettingsDivider()

            Button {
                showDeleteAccountAlert = true
            } label: {
                SettingsRow(
                    icon: "person.crop.circle.badge.minus",
                    label: "Delete account",
                    sub: "Permanently removes your account and all data",
                    kind: .action,
                    destructive: true
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var footer: some View {
        VStack(spacing: 14) {
            VStack(spacing: 8) {
                FooterRow(label: "Version", value: Bundle.main.versionWithBuild)
                FooterRow(label: "Developer", value: SecretConstants.developerName)
                FooterRow(label: "Contact", value: SecretConstants.supportEmail, link: true)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color("SurfaceAlt"))
            )

            Text("Made with care · Health data stays on your device")
                .font(.system(size: 11))
                .foregroundStyle(Color("InkMute"))
        }
        .padding(.horizontal, 22)
        .padding(.top, 20)
    }

    private func restorePurchases() async {
        isRestoringPurchases = true
        defer { isRestoringPurchases = false }
        do {
            try await subscriptionManager.restorePurchases()
            showRestoreSuccessAlert = true
        } catch {
            showRestoreErrorAlert = true
        }
    }
}

// MARK: - SettingsSection

struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                FWFTag(text: title)
                Spacer()
            }
            .padding(.horizontal, 22)
            .padding(.top, 22)
            .padding(.bottom, 8)

            VStack(spacing: 0) {
                content
            }
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color("Surface"))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color("Border"), lineWidth: 1)
            )
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - SettingsRow

struct SettingsRow: View {
    enum Kind { case nav, ext, action }

    let icon: String
    let label: String
    var sub: String? = nil
    var kind: Kind = .nav
    var destructive: Bool = false
    var loading: Bool = false

    private var foreground: Color { destructive ? Color("Move") : Color("Ink") }
    private var iconBackground: Color { destructive ? Color("MoveSoft") : Color("SurfaceAlt") }
    private var iconForeground: Color { destructive ? Color("Move") : Color("InkSoft") }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(iconForeground)
                .frame(width: 32, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(iconBackground)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 14.5, weight: .medium))
                    .tracking(-0.15)
                    .foregroundStyle(foreground)

                if let sub {
                    Text(sub)
                        .font(.system(size: 11.5))
                        .foregroundStyle(Color("InkMute"))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if loading {
                ProgressView().scaleEffect(0.7)
            } else {
                switch kind {
                case .nav, .action:
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color("InkFaint"))
                case .ext:
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color("InkFaint"))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .contentShape(Rectangle())
    }
}

// MARK: - SettingsDivider

/// Inset hairline between rows inside a SettingsSection.
struct SettingsDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color("Border"))
            .frame(height: 1)
            .padding(.leading, 60)  // align past the icon tile
    }
}

// MARK: - FooterRow

struct FooterRow: View {
    let label: String
    let value: String
    var link: Bool = false

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(Color("InkMute"))
            Spacer()
            if link, let url = URL(string: "mailto:\(value)") {
                Link(value, destination: url)
                    .foregroundStyle(Color("Brand"))
                    .fontWeight(.semibold)
            } else {
                Text(value)
                    .foregroundStyle(Color("Ink"))
                    .fontWeight(.medium)
                    .monospacedDigit()
            }
        }
        .font(.system(size: 12))
    }
}

// MARK: - Bundle.versionWithBuild

extension Bundle {
    /// e.g. "1.0.2 (build 47)" — used in the Settings footer.
    var versionWithBuild: String {
        let version = infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let build = infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "\(version) (build \(build))"
    }
}

// MARK: - Previews

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(
            emailUtility: MockEmailUtility(),
            serverEnvironmentManager: ServerEnvironmentManager(userDefaults: UserDefaults.standard),
            subscriptionManager: MockSubscriptionManager(),
            displayName: "Jordan Taylor",
            memberSinceLabel: "Member since Apr 2023 · Signed in with Apple",
            onDeleteAccount: { return true },
            onSignOut: { }
        )
    }
}
