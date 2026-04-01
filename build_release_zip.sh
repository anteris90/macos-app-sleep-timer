#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="Sleep Timer.app"
ZIP_NAME="SleepTimer.zip"

cd "$ROOT_DIR"

./build_app.sh
rm -f "$ZIP_NAME"
ditto -c -k --sequesterRsrc --keepParent "$APP_NAME" "$ZIP_NAME"

echo "Built $ROOT_DIR/$ZIP_NAME"