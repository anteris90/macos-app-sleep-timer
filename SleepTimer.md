# Sleep Timer

Sleep Timer is a native SwiftUI macOS app. The current app entrypoint is the Swift target in [Sources/SleepTimer/main.swift](Sources/SleepTimer/main.swift).

## Project notes

- The shipped app name is `Sleep Timer`.
- The repository and local folder may still use the older `SafariSleepTimer` name for historical reasons.
- Shared workspace instructions for AI-assisted changes live in [.github/copilot-instructions.md](.github/copilot-instructions.md).
- Feature changes should keep [README.md](README.md) and this file in sync.

## Current behavior

- Choose any installed macOS app to close when the timer expires.
- Save the selected app as the default choice for future launches.
- Select a preset delay of 15, 30, 45, 60, or 90 minutes, or enter a custom duration from 1 to 720 minutes.
- Start, cancel, or restart the timer from the same window.
- Present the controls in a restrained console-inspired interface.
- Switch between green and red console themes from the macOS menu bar.
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

Build the release archive used by Homebrew:

```bash
./build_release_zip.sh
```

The packaged app is created at:

```bash
Sleep Timer.app
```

The Homebrew release artifact is created at:

```bash
SleepTimer.zip
```

## Homebrew support

- The published cask lives in the dedicated private tap repository `anteris90/homebrew-macos-app-sleep-timer`.
- The cask installs [Sleep Timer.app](Sleep%20Timer.app) from a tagged GitHub release asset named `SleepTimer.zip`.
- Tagging a release like `v1.0.0` triggers [.github/workflows/release.yml](.github/workflows/release.yml), which builds the zip, publishes the release, and updates the tap repo automatically.
- The release workflow uses [generate_homebrew_cask.sh](generate_homebrew_cask.sh) and expects a repository secret named `HOMEBREW_TAP_PAT` with push access to the tap repo.
- Because the tap repo is private, installs require GitHub access to that repository and should use the explicit repository URL when tapping.

## Project layout

- [Package.swift](Package.swift): Swift package definition.
- [Sources/SleepTimer/main.swift](Sources/SleepTimer/main.swift): SwiftUI app, timer logic, app selection, and shutdown behavior.
- [build_app.sh](build_app.sh): Builds the release binary and wraps it in a macOS app bundle.
- [build_release_zip.sh](build_release_zip.sh): Builds the app bundle and packages it as `SleepTimer.zip` for GitHub releases and Homebrew.
- [generate_homebrew_cask.sh](generate_homebrew_cask.sh): Generates the versioned Homebrew cask file used by the tap repository.
- [Support/Info.plist](Support/Info.plist): Bundle metadata used for the packaged app.
- [.github/copilot-instructions.md](.github/copilot-instructions.md): Workspace instructions for future agent-assisted changes.
