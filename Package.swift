// swift-tools-version: 6.0
import PackageDescription

let package = Package(
	name: "MacOSAppSleepTimer",
	platforms: [
		.macOS(.v13)
	],
	products: [
		.executable(
			name: "MacOSAppSleepTimer",
			targets: ["MacOSAppSleepTimer"]
		)
	],
	targets: [
		.executableTarget(
			name: "MacOSAppSleepTimer"
		)
	]
)