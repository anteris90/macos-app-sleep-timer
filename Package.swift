// swift-tools-version: 6.0
import PackageDescription

let package = Package(
	name: "SafariSleepTimer",
	platforms: [
		.macOS(.v13)
	],
	products: [
		.executable(
			name: "SafariSleepTimer",
			targets: ["SafariSleepTimer"]
		)
	],
	targets: [
		.executableTarget(
			name: "SafariSleepTimer"
		)
	]
)