# FitWithFriends — Design System

> Editorial sport. Warm paper, near-black ink, a deep-indigo brand, and the
> three Apple Activity ring colors used as data. This system codifies the
> recently-redesigned **iPhone app** and its companion **Apple Watch app**.

---

## What FitWithFriends is

FitWithFriends is an **iOS app with a companion Apple Watch app** that lets you
create fitness competitions with friends. You build a competition, pick a
scoring rule, and invite people — or join a **public** competition to push
yourself further. Activity is pulled straight from **Apple Health / HealthKit**
(the three Activity rings: Move, Exercise, Stand — plus steps, distance, etc.),
so there's nothing to log manually. The whole product orbits one social loop:
*close your rings, climb the leaderboard, beat your friends.*

- **Auth:** Sign in with Apple only (privacy-first; email hiding supported).
- **Data:** HealthKit on the device → uploaded as daily summaries.
- **Competitions:** private (invite link) or public (browse & join); points-,
  steps-, calorie-, minute- or distance-based scoring; medals for the top three.
- **Platforms:** iPhone (primary, SwiftUI) and Apple Watch (companion, watchOS).
- **Backend:** Node.js / Express / PostgreSQL (not part of this design system).

### Sources used to build this system

Everything here was reverse-engineered from the official repository. The reader
is encouraged to explore it directly to build higher-fidelity work:

- **GitHub:** https://github.com/danoconnor/FitWithFriends
  - Design tokens (source of truth): `Clients/iOS/FitWithFriends/FitWithFriends/Resources/Colors.xcassets/`
  - Shared SwiftUI primitives: `Clients/iOS/FitWithFriends/FitWithFriends/Views/Custom Views/FWFStyles.swift`
  - Phone screens: `Clients/iOS/FitWithFriends/FitWithFriends/Views/**`
  - Watch screens: `Clients/iOS/FitWithFriends/FitWithFriends Watch App/Views/**`
  - Copy / voice reference: `.../Views/Competitions/MotivationalMessageProvider.swift`

> **Note on the two surfaces.** The Phone app fully adopts the new editorial
> "FWF" system (serif display, warm paper, indigo `Brand`). The Watch app shares
> that same system, applied via the **dark-mode tokens** appropriate to its
> always-dark canvas (indigo brand, serif competition names, green deltas,
> `#121316` surfaces). The legacy deep-blue `#11468F` (`FwFBrandingColor`) still
> exists in the source but is treated as legacy here. Both surfaces are
> documented below.

---

## CONTENT FUNDAMENTALS — how FitWithFriends talks

The voice is a **hype friend in your group chat**: warm, punchy, a little
competitive, never corporate. It motivates without nagging.

- **Person:** Speaks to **"you"**; the app is invisible. Friends are named
  ("**Alice Chen** is ahead of you"). Your own row always reads **"You"**.
- **Casing:** **Sentence case** everywhere — buttons, titles, sections
  ("Start a new competition", "Your Competitions", "Public Competitions").
  The only uppercase is the tiny tracked **micro-label/tag** ("PUBLIC", "PRO").
- **Tone:** Encouraging and high-energy, scaled to performance and time of day.
  Short declaratives. Sentence fragments are fine. Frequent imperatives:
  *"Time to move." "Don't leave points on the table." "Close them."*
- **Headlines** use an editorial two-part structure where the **second clause
  is italic serif**: *"Close rings. **Beat your friends.**"* /
  *"2 rings closed, **one to go.**"* This italic accent is the brand's signature.
- **Numbers lead.** Rank ("2nd of 6"), deltas ("+235 today"), countdowns
  ("4d left"), gaps ("390 pts behind 2nd"). Always concrete, always glanceable.
- **Motivational copy** is bucketed by *time of day* × *activity level* and
  rotates daily. Examples by intensity:
  - Low: *"The afternoon is calling. Time to move."*
  - Medium: *"Good momentum. Don't waste it."*
  - High: *"Most people are still warming up. You're done."*
- **Emoji:** rare and earned — a single 🏆 when you take the lead, confetti on a
  win. Never decorative, never in body copy. Don't sprinkle emoji.
- **Errors** are plain and humane, no codes: *"Something went wrong. Please try
  again."* / *"We're having trouble reading your activity information…"*
- **Reassurance** sits under CTAs in muted caption: *"Free to use · Requires
  Apple Watch or iPhone health data."*

**Do:** "You're in the lead 🏆" · "Day 8 of 12 · 67% of the way done" · "4d left"
**Don't:** "CONGRATULATIONS!!! 🎉🎉" · "Click here to view your dashboard" · "Utilize the leaderboard module"

---

## VISUAL FOUNDATIONS

**The vibe:** an editorial sports magazine that happens to be an app. Warm
paper instead of stark white, a serious near-black ink, one disciplined indigo,
and the Apple ring colors reserved strictly for *data*. Calm and premium, with
energy delivered through typography and numbers rather than gradients or noise.

### Color
- **Backgrounds are warm, not white.** The canvas is `--bg` `#f6f4ef` (paper);
  cards sit on pure `--surface` white above it. Chips/wells use `--surface-alt`
  `#f1eee6`. This warmth is core to the brand — never ship on `#ffffff` canvas.
- **Ink ramp** is a cool near-black `#16181d` stepping down through soft / mute
  / faint. Text is ink, not pure black.
- **One brand color:** deep indigo `--brand` `#2a3f7a`, brightening to
  `--brand-hi` `#3c5bbf` for gradients/links, with a pale `--brand-soft`
  `#e9ecf7` for tinted fills. Used sparingly — chips, progress, the "you" row.
- **Ring colors are data, not decoration.** Move red `#fa114f`, Exercise green
  `#92e82a`, Stand cyan `#1eeaef` only ever represent their metric (or, for
  green, a positive delta / celebration). `--sun` amber `#f2a03e` = Pro/premium.
- **Medals:** gold `#d9a33a`, silver `#a8aeb8`, bronze `#b27042` for ranks 1–3.
- **Full dark mode** is first-class with hand-tuned variants (brand shifts to a
  lighter periwinkle `#7c97ff`; rings get brighter). See `colors_and_type.css`.

### Type
- **Two families.** Body/UI is the Apple **system sans (SF Pro)**. Display
  moments use the Apple **serif (New York)** at *regular* weight — used for the
  hero headline and every **competition name**. The serif is the editorial soul.
- **Italic serif = accent.** The second clause of a display headline (or a
  celebratory accent) is italic and brand-colored.
- **Numbers** are bold, **tabular/monospaced digits**, tracked tight (-0.02em):
  ranks ("2nd"), big scores, countdowns. The Watch hero rank uses **SF Pro
  Rounded**.
- **Micro-labels** (tags/chips) are 10.5px, semibold, UPPERCASE, +0.1em tracking.
- Display headlines are tracked tight with slightly negative line spacing.

### Shape, elevation & borders
- **Corner radii:** cards `22px`, primary button `16px`, dashed secondary
  button `18px`, rows/fields `14px`, small wells `12px`, chips full-pill. All
  use **continuous (squircle)** corners on device — prefer large smooth radii.
- **Cards (light):** white surface + soft layered shadow
  (`0 8px 24px rgba(0,0,0,.06)` + `0 1px 2px rgba(0,0,0,.04)`), **no border**.
- **Cards (dark):** shadows are invisible on dark surfaces, so elevation becomes
  a **1px hairline border** (`rgba(255,255,255,.06)`) instead. This swap is the
  rule, not an exception.
- **Borders** are always ink/white at low alpha (`--border` 8%, `--border-strong`
  14%) — never a solid gray line.
- **Floating chrome** (back / share / menu on the detail sheet) = 38px white
  circles with a soft drop shadow, sitting above the scroll content.

### Signature details
- **Dashed brand outline** on the secondary button ("Start a new competition")
  — a 1.5px dashed indigo stroke `[6,4]`. Distinctive; use for "create/add".
- **Deterministic avatars:** initials on a color picked by hashing the name,
  from an 8-color palette (includes the ring + brand hues). Medal rank adds a
  white inner ring + colored outer ring.
- **The "you" row** on a leaderboard is brand-tinted: `--brand-soft` fill, a
  1.5px `--brand` border, and a soft brand shadow — it pops out of the list.
- **Hero numbers** carry the screen: rank-as-hero ("2nd of 6"), standing card,
  today-delta. Stat-forward, not chart-forward.
- **Progress** is always a thin (3–6px) capsule track in a soft tint with a
  solid (or brand→brand-hi gradient) fill.
- A welcome-screen leaderboard preview card is rotated **-1.5°** for a playful,
  physical "card on a table" feel — a rare, deliberate tilt.

### Motion
- **Springs, gently.** State changes animate with `spring(duration: 0.4)`
  (error banners slide+fade from the top edge). Sheets use the native iOS
  presentation with a drag indicator.
- **Confetti** overlays a competition win. Pull-to-refresh on the home feed.
- Otherwise restrained — no parallax, no looping background motion. Energy comes
  from content, not animation.

### Layout
- **Single-column, card-stacked feeds** with 16px horizontal page margins and
  ~16px inter-card spacing. Sections are introduced by a sentence-case header.
- A **greeting row** (subtitle + bold title + circular settings gear) replaces a
  traditional nav bar; the home feed has no chrome bar.
- Content-first: today's activity → public competitions → your competitions →
  the dashed "create" button.

### Backgrounds & imagery
- **No photography, no gradients-as-decoration, no textures.** The background is
  flat warm paper. The product *is* the data. The only gradient anywhere is the
  brand→brand-hi fill inside a progress bar.

---

## ICONOGRAPHY

- **System:** **Apple SF Symbols** throughout — there is no custom icon font and
  no bespoke SVG icon set in the codebase. Glyphs are rendered at semibold,
  inheriting the ink/brand color of their context.
- **Common symbols seen in the apps:** `figure.run` (wordmark mark), `applelogo`
  (sign-in), `plus` (create), `globe` / `lock.fill` (public/private),
  `gearshape.fill` (settings), `ellipsis` (menus), `chevron.left`,
  `square.and.arrow.up` (share), `calendar`, `trophy`, `star.fill` (Pro),
  `arrow.up` (positive delta), `checkmark.circle.fill`, `heart.text.square`,
  `exclamationmark.triangle.fill` (errors).
- **For web/HTML recreations:** SF Symbols can't be embedded outside Apple
  platforms. Use **SF Symbols directly when targeting Apple**, otherwise
  substitute **Lucide** (`lucide.dev`) — a clean, consistent stroke set whose
  weight matches SF Symbols well. The UI kits in this system load Lucide from
  CDN and map symbol → nearest Lucide name. **⚠️ Substitution flagged:** Lucide
  is a stand-in for SF Symbols on non-Apple targets; on-device, prefer the real
  SF Symbol named above.
- **Emoji as icon:** only the 🏆 trophy on a lead state and 🎉/confetti on a win.
  No unicode dingbats used as UI icons.
- **App icon** (`assets/app-icon-legacy.png`): the legacy mark — three white
  fitness figures (yoga / overhead press / flex) on the legacy deep blue
  `#11468F`. ⚠️ This icon predates the editorial redesign and reads as the old
  brand; treat it as legacy and flag if a new mark is needed.

---

## Index / manifest

Root files:
- **`README.md`** — this file (context, content, visual foundations, iconography, index).
- **`colors_and_type.css`** — all color tokens (light + dark) + semantic type classes & primitives. Import this in every artifact.
- **`SKILL.md`** — Agent-Skill front-matter so this folder works as a Claude skill.
- **`assets/`** — `app-icon-legacy.png` (legacy app icon).
- **`preview/`** — design-system specimen cards (rendered in the Design System tab).
- **`ui_kits/phone/`** — iPhone app UI kit (README + index.html + JSX components).
- **`ui_kits/watch/`** — Apple Watch app UI kit (README + index.html + JSX components).

No slide template was provided in the source, so no `slides/` were created.
