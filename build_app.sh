#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="Sleep Timer.app"
EXECUTABLE_NAME="SleepTimer"
BUILD_DIR="$ROOT_DIR/.build/release"
APP_DIR="$ROOT_DIR/$APP_NAME"

cd "$ROOT_DIR"
swift build -c release

rm -rf "$ROOT_DIR/SafariSleepTimer.app"
rm -rf "$ROOT_DIR/macOS App Sleep Timer.app"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"

cp "$BUILD_DIR/$EXECUTABLE_NAME" "$APP_DIR/Contents/MacOS/$EXECUTABLE_NAME"
cp "$ROOT_DIR/Support/Info.plist" "$APP_DIR/Contents/Info.plist"
cp "$ROOT_DIR/Support/AppIcon.icns" "$APP_DIR/Contents/Resources/AppIcon.icns"

codesign --force --sign - "$APP_DIR" >/dev/null 2>&1 || true

echo "Built $APP_DIR"