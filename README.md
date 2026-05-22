# STOIC OS

A private, on-device reasoning companion for macOS — it helps you choose well,
account for your time, and become the specific person you decide to be.

**Version 0.1.0** — early development build.

## What works now

- A reasoning core (`StoicKit`) — built and unit-tested.
- A SwiftUI app with ten screens: app lock, onboarding, dashboard, decisions,
  goals, timetable, time audit, brag document, ideal self, settings.
- The Decision Engine: describe a situation and get a reasoned, structured
  recommendation — options, consequences, the diplomatic approach, the strongest
  counter-argument — produced entirely on-device.
- Onboarding, goals, the brag document, and manual time-audit logging.

Some screens (dashboard, timetable, ideal self) currently render their layout
with their deeper logic still in progress.

## Build & run

Requirements: macOS 14+, Xcode 26+, XcodeGen (`brew install xcodegen`).

```bash
xcodegen generate
open STOICOS.xcodeproj
# In Xcode: select the STOICOS scheme and Run (⌘R).
```

The first decision session downloads a local model from Hugging Face once
(~1.8 GB for the default 3B model); afterwards all inference runs offline.
The model can be changed in Settings — a larger model gives stronger reasoning.

Run the core tests:

```bash
cd Packages/StoicKit && swift test
```

## Layout

```
project.yml            XcodeGen spec — source of truth for the Xcode project
Packages/StoicKit/     Reasoning core: models, scoring, retrieval, prompts
App/Sources/
  Inference/           Inference provider, on-device model, reasoning engine
  Persistence/         Local storage
  Views/               Ten app screens
```

## Architecture notes

- Single-process app. On-device inference sits behind an `InferenceProvider`
  protocol so it can later be moved into its own service.
- V0 persists to local JSON files; a SQLite-backed store is planned.
- All inference is local — nothing is sent off the device.

## Principles

STOIC OS optimises for what is genuinely beneficial to the user — strategic,
high-agency, calibrated, and ethically ambitious. It is blunt and direct with
the user, and it never coaches manipulation or dishonesty toward other people.
