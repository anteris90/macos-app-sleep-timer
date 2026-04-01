// swift-tools-version: 6.0
import PackageDescription

let package = Package(
	name: "SleepTimer",
	platforms: [
		.macOS(.v13)
	],
	products: [
		.executable(
			name: "SleepTimer",
			targets: ["SleepTimer"]
		)
	],
	targets: [
		.executableTarget(
			name: "SleepTimer"
		)
	]
)