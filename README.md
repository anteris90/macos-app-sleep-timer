# Sleep Timer

Sleep Timer is a native SwiftUI macOS app that closes a selected application after a configurable delay.

## Features

- Choose any installed macOS app to target.
- Save the selected app as the default choice for future launches.
- Pick a preset delay of 15, 30, 45, 60, or 90 minutes, or enter a custom duration from 1 to 720 minutes.
- Start, cancel, restart, or immediately trigger the shutdown flow.
- Show a 10-second warning phase before the selected app is closed.
- Close the target app gracefully through AppKit if it is running.

## Requirements

- macOS 13 or later
- Xcode command line tools with Swift 6 support

## Project Layout

- `Package.swift`: Swift package definition
- `Sources/SleepTimer/main.swift`: SwiftUI app and timer logic
- `Support/Info.plist`: app bundle metadata
- `Support/AppIcon.icns`: bundled app icon
- `build_app.sh`: release build and app bundle packaging script

## Build

Build the debug target:

```bash
swift build
```

Build the packaged macOS app bundle:

```bash
./build_app.sh
```

Build the release zip used by Homebrew:

```bash
./build_release_zip.sh
```

The packaged app is created as:

```bash
Sleep Timer.app
```

## Run

Launch the packaged app from Finder, or run it from the project directory:

```bash
open -n "Sleep Timer.app"
```

## Homebrew

This repository now includes a cask at `Casks/sleep-timer.rb`.

Install from this repository as a custom tap:

```bash
brew tap anteris90/macos-app-sleep-timer https://github.com/anteris90/macos-app-sleep-timer
brew install --cask sleep-timer
```

The cask downloads `SleepTimer.zip` from a tagged GitHub release. Pushing a tag like `v1.0.0` triggers the release workflow in `.github/workflows/release.yml`, and the cask should be updated to the matching version and SHA-256 for each release.

## How It Works

1. Choose the app you want to close.
2. Optionally save it as the default app.
3. Select a preset delay or enter a custom duration.
4. Start the timer.
5. When the timer expires, Sleep Timer enters a 10-second warning state.
6. If not cancelled or restarted, the selected app is terminated gracefully.

## Notes

- The app targets running applications by bundle identifier when available.
- Default app selection is stored locally using a persisted bookmark.
- The GitHub repository name may differ from the shipped app name.