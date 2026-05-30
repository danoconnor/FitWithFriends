# FitWithFriends — Watch UI Kit

A high-fidelity recreation of the **companion Apple Watch app** (watchOS,
SwiftUI). Cosmetic clickthrough — visuals match the source, data is faked.

## Run it
Open `index.html`.

1. **Competitions pager** — a vertical TabView of competition cards. Each card:
   competition name (headline), a tinted **hero block** (your rank ordinal in
   rounded numerals + total points + "+today"), a divider, the **top-3**
   leaderboard rows with medal badges, and a "You're 2nd of 5" footer. Tap the
   **page dots** to switch competitions.
2. **Daily details** — tap any leaderboard row to drill into that person's
   per-day points (a carousel-style list of day cards with Cal / Min / hr). Tap
   the back chevron to return.
3. **Signed-out** state is also available (`WatchSignedOut`).

## Files
- `index.html` — entry; loads React + Babel then the scripts below.
- `WatchFrame.jsx` — 45mm Apple Watch bezel + crown; screen designed at
  198×242 pt, scaled up for legibility.
- `WatchScreens.jsx` — `WatchPager`, `WatchCompCard`, `WatchRow`,
  `WatchDailyDetails`, `WatchSignedOut`, plus the watch color constants.
- `app.jsx` — view switcher, mounts into `WatchFrame`.

## Fidelity notes
- **Aligned to the shared design system.** The Watch runs the design system's
  **dark-mode tokens** (from `../../colors_and_type.css`, via a
  `[data-theme="dark"]` wrapper): the indigo **Brand** `#7c97ff`, serif
  competition names, **green** `+today` deltas, paper-dark surfaces
  (`#121316` canvas, `#1b1d22` cards), and gold/silver/bronze medals — matching
  the Phone app rather than the legacy branding blue.
- Hero numerals use **SF Pro Rounded** (`--font-rounded`), matching the app's
  `.rounded` design font; competition names use **New York serif**, same as the
  Phone app's editorial titles.
- Source: `Clients/iOS/FitWithFriends/FitWithFriends Watch App/Views/**`
  (layout); colors/type unified to the redesigned system per design direction.
