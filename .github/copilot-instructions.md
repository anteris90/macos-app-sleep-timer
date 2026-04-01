# Sleep Timer Workspace Instructions

- This repository builds a native macOS SwiftUI app named `Sleep Timer`.
- Keep the shipped product name as `Sleep Timer`. Do not rename the GitHub repository unless explicitly asked.
- When adding or changing features, update `README.md` and `SleepTimer.md` in the same change so docs stay aligned.
- Prefer minimal, focused edits that preserve the current SwiftUI structure in `Sources/SleepTimer/main.swift`.
- Keep the app behavior general-purpose: the timer targets a user-selected macOS app, not Safari specifically.
- Preserve the saved-default-app behavior that uses a persisted bookmark in `UserDefaults` unless the task explicitly changes it.
- Close target apps gracefully through AppKit APIs. Do not switch to force-kill behavior unless explicitly requested.
- After product code changes, verify with `swift build`. When bundle metadata, executable names, or packaging change, also run `./build_app.sh`.