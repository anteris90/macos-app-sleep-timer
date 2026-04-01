cask "sleep-timer" do
	version :latest
	sha256 :no_check

	url "https://github.com/anteris90/macos-app-sleep-timer/releases/latest/download/SleepTimer.zip",
		verified: "github.com/anteris90/macos-app-sleep-timer/"
	name "Sleep Timer"
	desc "Close a selected macOS app after a configurable delay"
	homepage "https://github.com/anteris90/macos-app-sleep-timer"

	depends_on macos: ">= :ventura"

	app "Sleep Timer.app"
end