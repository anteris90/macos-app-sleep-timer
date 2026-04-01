#!/bin/zsh

set -euo pipefail

if [[ $# -lt 2 || $# -gt 3 ]]; then
	echo "Usage: $0 <version> <sha256> [output-path]" >&2
	exit 1
fi

VERSION="$1"
SHA256="$2"
OUTPUT_PATH="${3:-}"

read -r -d '' CASK_CONTENT <<EOF || true
cask "sleep-timer" do
	version "$VERSION"
	sha256 "$SHA256"

	url "https://github.com/anteris90/macos-app-sleep-timer/releases/download/v#{version}/SleepTimer.zip",
		verified: "github.com/anteris90/macos-app-sleep-timer/"
	name "Sleep Timer"
	desc "Close a selected macOS app after a configurable delay"
	homepage "https://github.com/anteris90/macos-app-sleep-timer"

	depends_on macos: ">= :ventura"

	app "Sleep Timer.app"
end
EOF

if [[ -n "$OUTPUT_PATH" ]]; then
	mkdir -p "$(dirname "$OUTPUT_PATH")"
	printf "%s\n" "$CASK_CONTENT" > "$OUTPUT_PATH"
else
	printf "%s\n" "$CASK_CONTENT"
fi