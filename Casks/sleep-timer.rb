cask "sleep-timer" do
	version "1.0.0"
	sha256 "32e8096b1e908ce950aa233c04bb68c2d8ad1b6ab29a57f86609f6ac7562f9b4"

	url "https://github.com/anteris90/macos-app-sleep-timer/releases/download/v#{version}/SleepTimer.zip",
		verified: "github.com/anteris90/macos-app-sleep-timer/"
	name "Sleep Timer"
	desc "Close a selected macOS app after a configurable delay"
	homepage "https://github.com/anteris90/macos-app-sleep-timer"

	depends_on macos: ">= :ventura"

	app "Sleep Timer.app"
end