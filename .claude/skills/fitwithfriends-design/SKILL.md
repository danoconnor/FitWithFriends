---
name: fitwithfriends-design
description: Use this skill to generate well-branded interfaces and assets for FitWithFriends, either for production or throwaway prototypes/mocks/etc. Contains essential design guidelines, colors, type, fonts, assets, and UI kit components for prototyping.
user-invocable: true
---

Read the README.md file at ../../../Design/README.md, and explore the other available files in the Design directory.

FitWithFriends is an iOS + Apple Watch app for social fitness competitions. The
design language is "editorial sport": warm paper backgrounds, near-black ink, a
deep-indigo brand, a New York serif for display moments, and the three Apple
Activity ring colors used strictly as data accents.

Key files in the <repo root>/Design directory:
- `README.md` — full context: content/voice rules, visual foundations, iconography, manifest.
- `colors_and_type.css` — all color tokens (light + dark) + semantic type classes. Import this in every artifact.
- `preview/` — design-system specimen cards.
- `ui_kits/phone/` — interactive iPhone app recreation (React/JSX).
- `ui_kits/watch/` — interactive Apple Watch app recreation (React/JSX). Note: the Watch uses the legacy blue `#11468F`, not the Phone's indigo.
- `assets/` — the (legacy) app icon.

If creating visual artifacts (slides, mocks, throwaway prototypes, etc), copy
assets out and create static HTML files for the user to view. If working on
production code, copy assets and read the rules here to become an expert in
designing with this brand.

If the user invokes this skill without any other guidance, ask them what they
want to build or design, ask some questions, and act as an expert designer who
outputs HTML artifacts _or_ production code, depending on the need.
