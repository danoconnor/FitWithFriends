# FitWithFriends — Phone UI Kit

A high-fidelity, interactive recreation of the **redesigned iPhone app**
(SwiftUI). It is a cosmetic clickthrough, not production code — the visuals and
interactions match the source, the data is faked.

## Run it
Open `index.html`. The flow:

1. **Welcome** — wordmark, editorial hero (*"Close rings. Beat your friends."*),
   a tilted leaderboard preview card, and Sign in with Apple. → tap to continue.
2. **Home feed** — greeting row + settings gear, today's Activity rings + metric
   strip, your competitions (rank-as-hero card), a public competition card, and
   the dashed "Start a new competition" button. → tap a competition.
3. **Competition detail** — floating chrome (back / share / menu), serif title,
   a standing card (rank + time-left + gradient progress), and the full
   leaderboard with the brand-tinted **"You"** row.
4. **Settings sheet** — tap the gear; a bottom sheet with profile + rows. Sign
   out returns to Welcome.

## Files
- `index.html` — entry; loads React + Babel, then the scripts below in order.
- `ios-frame.jsx` — iOS device bezel (starter component; `IOSDevice`).
- `Primitives.jsx` — `Icon`, `Avatar`, `Card`, `Chip`, `PrimaryButton`,
  `SecondaryButton`, `Display`, `ActivityRings`. Mirrors `FWFStyles.swift`.
- `Screens.jsx` — `WelcomeScreen`, `HomeScreen`, `DetailScreen` + sub-cards.
- `app.jsx` — state machine + `SettingsSheet`, mounts into `IOSDevice`.

## Fidelity notes
- Colors & type come from `../../colors_and_type.css` (the system tokens).
- **Icons** are a curated inline stroke set standing in for **SF Symbols**
  (which can't ship off-Apple). On device, use the real SF Symbol names listed
  in the root README's ICONOGRAPHY section. ⚠️ flagged substitution.
- **Activity rings** are drawn as three concentric SVG arcs to approximate
  Apple's `HKActivitySummaryView` (the real app embeds the native ring view).
- The source for every screen lives in
  `Clients/iOS/FitWithFriends/FitWithFriends/Views/**` of the GitHub repo.
