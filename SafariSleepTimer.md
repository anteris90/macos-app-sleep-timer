# macOS App Sleep Timer

macOS App Sleep Timer is a native SwiftUI macOS app. The old AppleScript source remains in the repository as a legacy reference, but the current app entrypoint is the Swift target in [Sources/MacOSAppSleepTimer/main.swift](Sources/MacOSAppSleepTimer/main.swift).

## Current behavior

- Choose any installed macOS app to close when the timer expires.
- Save the selected app as the default choice for future launches.
- Select a delay of 15, 30, 45, 60, or 90 minutes.
- Start, cancel, or restart the timer from the same window.
- View a live countdown and current selected-app status.
- Enter a 10-second warning phase before the selected app is closed.
- Close the selected app gracefully through AppKit if it is running.

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
macOS App Sleep Timer.app
```

## Project layout

- [Package.swift](Package.swift): Swift package definition.
- [Sources/MacOSAppSleepTimer/main.swift](Sources/MacOSAppSleepTimer/main.swift): SwiftUI app, timer logic, app selection, and shutdown behavior.
- [build_app.sh](build_app.sh): Builds the release binary and wraps it in a macOS app bundle.
- [Support/Info.plist](Support/Info.plist): Bundle metadata used for the packaged app.

## Legacy AppleScript

[SafariSleepTimer.applescript](SafariSleepTimer.applescript) and the earlier checked-in Safari app bundle reflect the original AppleScript implementation and are no longer the primary source for the current app behavior.
