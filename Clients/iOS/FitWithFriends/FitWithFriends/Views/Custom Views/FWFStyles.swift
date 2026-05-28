//
//  FWFStyles.swift
//  FitWithFriends
//
//  Created by Dan O'Connor on 3/26/26.
//
//  Shared SwiftUI primitives for the FitWithFriends design system.
//  Reads colors from the `Resources/Colors.xcassets` palette (Bg, Ink,
//  Brand, Move, Exercise, Stand, Sun, etc.) — never hard-code colors here.
//

import SwiftUI

// MARK: - Card Modifier

struct FWFCardModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    var padding: CGFloat = 16
    var cornerRadius: CGFloat = 22

    func body(content: Content) -> some View {
        // Dark mode: drop shadows on dark surfaces are invisible, so add a
        // 1pt Border overlay as the elevation cue instead.
        let isDark = colorScheme == .dark

        return content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color("Surface"))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color("Border"), lineWidth: isDark ? 1 : 0)
            )
            .shadow(color: .black.opacity(isDark ? 0.30 : 0.06),
                    radius: isDark ? 16 : 24, x: 0, y: 8)
            .shadow(color: .black.opacity(isDark ? 0.00 : 0.04),
                    radius: 2, x: 0, y: 1)
    }
}

extension View {
    func fwfCard(padding: CGFloat = 16, cornerRadius: CGFloat = 22) -> some View {
        modifier(FWFCardModifier(padding: padding, cornerRadius: cornerRadius))
    }
}

// MARK: - Error Banner

struct FWFErrorBanner: View {
    let message: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color("Move"))

            Text(message)
                .font(.subheadline)
                .foregroundStyle(Color("Ink"))

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color("MoveSoft"))
        )
        .padding(.horizontal, 16)
    }
}

// MARK: - Tag (uppercase micro label)

struct FWFTag: View {
    let text: String
    var color: Color = Color("InkMute")
    var background: Color? = nil

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 10.5, weight: .semibold))
            .tracking(1.0)
            .foregroundStyle(color)
            .padding(.horizontal, background == nil ? 0 : 8)
            .padding(.vertical, background == nil ? 0 : 4)
            .background(
                Group {
                    if let background {
                        Capsule().fill(background)
                    }
                }
            )
    }
}

// MARK: - BigNum (hero stat)

struct FWFBigNum: View {
    let value: String
    var size: CGFloat = 44
    var color: Color = Color("Ink")
    var suffix: String? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(value)
                .font(.system(size: size, weight: .bold))
                .monospacedDigit()
                .tracking(-0.02 * size)
                .foregroundStyle(color)
            if let suffix {
                Text(suffix)
                    .font(.system(size: size * 0.32, weight: .medium))
                    .foregroundStyle(Color("InkMute"))
            }
        }
    }
}

// MARK: - Editorial display headline (New York serif)

struct FWFDisplay: View {
    /// Each tuple: `(text, isItalic)`. Italic fragments can be rendered in `italicColor`
    /// for the accent moments in the design (e.g. "*Beat your friends.*").
    let parts: [(String, Bool)]
    var size: CGFloat = 44
    var color: Color = Color("Ink")
    var italicColor: Color? = nil
    var alignment: TextAlignment = .leading

    var body: some View {
        parts.reduce(Text("")) { acc, part in
            var t = Text(part.0)
                .font(.system(size: size, weight: .regular, design: .serif))
            if part.1 {
                t = t.italic().foregroundColor(italicColor ?? color)
            } else {
                t = t.foregroundColor(color)
            }
            return acc + t
        }
        .tracking(-0.02 * size)
        .lineSpacing(-size * 0.05)
        .multilineTextAlignment(alignment)
        .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Primary Button (ink background, white text)

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
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
            }
            // BgDeep is near-white in light mode and near-black in dark, so it
            // inverts cleanly with Ink (the button background) in both modes.
            .foregroundStyle(Color("BgDeep"))
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color("Ink"))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Secondary Button (dashed brand outline)

struct FWFSecondaryButton: View {
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
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundStyle(Color("Brand"))
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(
                        Color("Brand").opacity(0.7),
                        style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Avatar (deterministic color from name)

struct FWFAvatar: View {
    let name: String
    var size: CGFloat = 36
    var ring: Color? = nil

    private static let palette: [Color] = [
        Color(hex: "FA114F"), Color(hex: "3C5BBF"), Color(hex: "92E82A"),
        Color(hex: "F2A03E"), Color(hex: "1EEAEF"), Color(hex: "D9A33A"),
        Color(hex: "7A5BC0"), Color(hex: "2A8C66"),
    ]

    private var initials: String {
        let pieces = name.split(separator: " ").prefix(2)
        let chars = pieces.compactMap { $0.first.map(String.init) }
        return chars.joined().uppercased()
    }

    private var bg: Color {
        let hash = name.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return Self.palette[hash % Self.palette.count]
    }

    var body: some View {
        Text(initials)
            .font(.system(size: size * 0.36, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(Circle().fill(bg))
            .overlay(
                Group {
                    if let ring {
                        Circle()
                            .strokeBorder(.white, lineWidth: 1.5)
                            .padding(-1.5)
                        Circle()
                            .strokeBorder(ring, lineWidth: 2.5)
                            .padding(-3.5)
                    }
                }
            )
    }
}

// MARK: - Feature Row (still used by onboarding screens)

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
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color("Ink"))

                Text(description)
                    .font(.system(size: 14))
                    .foregroundStyle(Color("InkSoft"))
            }
        }
    }
}

// MARK: - Previews

#Preview("Card") {
    Text("Card content")
        .frame(maxWidth: .infinity)
        .fwfCard()
        .padding(.horizontal, 16)
        .background(Color("Bg"))
}

#Preview("Buttons") {
    VStack(spacing: 16) {
        FWFPrimaryButton("Sign in with Apple", icon: "applelogo") {}
        FWFSecondaryButton("Start a new competition", icon: "plus") {}
    }
    .padding()
    .background(Color("Bg"))
}

#Preview("Display") {
    FWFDisplay(
        parts: [("Close rings. ", false), ("Beat your friends.", true)],
        size: 44,
        italicColor: Color("Brand")
    )
    .padding()
    .background(Color("Bg"))
}

#Preview("BigNum") {
    FWFBigNum(value: "275", size: 44, color: Color("Ink"), suffix: "pts")
        .padding()
}

#Preview("Tag") {
    HStack {
        FWFTag(text: "Competition complete", color: Color("Brand"), background: Color("BrandSoft"))
        FWFTag(text: "Pro", color: Color("Sun"))
    }
    .padding()
}

#Preview("Avatar") {
    HStack(spacing: 16) {
        FWFAvatar(name: "Alice Chen", size: 36)
        FWFAvatar(name: "Bob Marley", size: 48, ring: Color("Gold"))
        FWFAvatar(name: "Sam Smith", size: 56, ring: Color("Silver"))
    }
    .padding()
}

#Preview("Error Banner") {
    FWFErrorBanner(message: "Something went wrong. Please try again.")
}
