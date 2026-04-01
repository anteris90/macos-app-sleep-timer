# Safari Sleep Timer

Safari Sleep Timer is now a native SwiftUI macOS app. The old AppleScript source remains in the repository as a legacy reference, but the current app entrypoint is the Swift target in [Sources/SafariSleepTimer/main.swift](Sources/SafariSleepTimer/main.swift).

## Current behavior

- Select a delay of 15, 30, 45, 60, or 90 minutes.
- Start, cancel, or restart the timer from the same window.
- View a live countdown and current Safari status.
- Enter a 10-second warning phase before Safari is closed.
- Close Safari gracefully through AppKit if it is running.

## Build

Debug build:

```bash
swift build
```

Bundle the app:

```bash
./build_app.sh
```

The packaged app is created at:

```bash
SafariSleepTimer.app
```

## Project layout

- [Package.swift](Package.swift): Swift package definition.
- [Sources/SafariSleepTimer/main.swift](Sources/SafariSleepTimer/main.swift): SwiftUI app, timer logic, and Safari shutdown behavior.
- [build_app.sh](build_app.sh): Builds the release binary and wraps it in a macOS app bundle.
- [Support/Info.plist](Support/Info.plist): Bundle metadata used for the packaged app.

## Legacy AppleScript

[SafariSleepTimer.applescript](SafariSleepTimer.applescript) and the checked-in [SafariSleepTimer.app](SafariSleepTimer.app) reflect the earlier AppleScript implementation and are no longer the primary source for the current app behavior.
