import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct DelayOption: Identifiable, Hashable {
	let minutes: Int

	var id: Int { minutes }
	var label: String { "\(minutes) min" }
	var seconds: Int { minutes * 60 }
}

struct TargetApplication: Equatable {
	let url: URL
	let displayName: String
	let bundleIdentifier: String?

	static func from(url: URL) -> TargetApplication {
		let bundle = Bundle(url: url)
		let displayName =
			(bundle?.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String) ??
			(bundle?.object(forInfoDictionaryKey: "CFBundleName") as? String) ??
			url.deletingPathExtension().lastPathComponent

		return TargetApplication(
			url: url,
			displayName: displayName,
			bundleIdentifier: bundle?.bundleIdentifier
		)
	}
}

enum TimerPhase {
	case idle
	case running
	case warning
}

enum DurationSelectionMode: String, CaseIterable, Identifiable {
	case preset
	case custom

	var id: String { rawValue }

	var label: String {
		switch self {
		case .preset:
			return "Presets"
		case .custom:
			return "Custom"
		}
	}
}

@MainActor
final class SleepTimerViewModel: ObservableObject {
	private enum DefaultsKey {
		static let defaultAppBookmark = "defaultAppBookmark"
	}

	let options = [15, 30, 45, 60, 90].map(DelayOption.init)
	private let defaultOption = DelayOption(minutes: 30)
	private let minimumCustomMinutes = 1
	private let maximumCustomMinutes = 720

	@Published var selectedOption: DelayOption
	@Published var durationSelectionMode: DurationSelectionMode = .preset
	@Published var customMinutesText: String = ""
	@Published var selectedApp: TargetApplication?
	@Published var phase: TimerPhase = .idle
	@Published var activeDuration: Int = 0
	@Published var remainingSeconds: Int = 0
	@Published var warningSecondsRemaining: Int = 10
	@Published var statusText: String
	@Published var appStatusText: String

	private var countdownTask: Task<Void, Never>?

	init() {
		let savedApp = Self.loadSavedDefaultApp()
		selectedOption = defaultOption
		selectedApp = savedApp
		remainingSeconds = defaultOption.seconds

		if let savedApp {
			statusText = "Loaded default app: \(savedApp.displayName). Choose a duration, then start the timer."
		} else {
			statusText = "Choose an app and duration, then start the timer."
		}

		appStatusText = Self.statusText(for: savedApp)
	}

	deinit {
		countdownTask?.cancel()
	}

	var isRunning: Bool {
		phase == .running || phase == .warning
	}

	var hasSelectedApp: Bool {
		selectedApp != nil
	}

	var selectedAppName: String {
		selectedApp?.displayName ?? "No app selected"
	}

	var primaryButtonTitle: String {
		switch phase {
		case .idle:
			return "Start"
		case .running:
			return "Start New Timer"
		case .warning:
			return "Close Now"
		}
	}

	var secondaryButtonTitle: String {
		switch phase {
		case .idle:
			return "Reset"
		case .running:
			return "Cancel"
		case .warning:
			return "New Timer"
		}
	}

	var tertiaryButtonTitle: String? {
		phase == .warning ? "Cancel" : nil
	}

	var progressValue: Double {
		switch phase {
		case .idle:
			return 0
		case .running:
			guard activeDuration > 0 else { return 0 }
			return Double(activeDuration - remainingSeconds)
		case .warning:
			return Double(10 - warningSecondsRemaining)
		}
	}

	var progressTotal: Double {
		switch phase {
		case .idle:
			return 1
		case .running:
			return Double(max(activeDuration, 1))
		case .warning:
			return 10
		}
	}

	var progressLabel: String {
		switch phase {
		case .idle:
			return "Ready"
		case .running:
			return "Time remaining: \(format(seconds: remainingSeconds))"
		case .warning:
			return "Closing \(selectedAppName) in: \(warningSecondsRemaining)s"
		}
	}

	var customMinutesHelpText: String {
		"Enter \(minimumCustomMinutes)-\(maximumCustomMinutes) minutes."
	}

	func primaryAction() {
		guard phase == .warning || hasSelectedApp else {
			statusText = "Choose an app first."
			return
		}

		switch phase {
		case .idle:
			startTimerForCurrentSelection()
		case .running:
			startTimerForCurrentSelection()
		case .warning:
			closeSelectedAppNow(triggeredAutomatically: false)
		}
	}

	func secondaryAction() {
		switch phase {
		case .idle:
			resetSelection()
		case .running:
			cancelTimer(reason: "Timer cancelled.")
		case .warning:
			startTimerForCurrentSelection()
		}
	}

	func tertiaryAction() {
		guard phase == .warning else { return }
		cancelTimer(reason: "App close cancelled.")
	}

	func chooseApp() {
		let panel = NSOpenPanel()
		panel.title = "Choose an app"
		panel.message = "Select the app to close when the timer ends."
		panel.prompt = "Choose App"
		panel.canChooseFiles = true
		panel.canChooseDirectories = false
		panel.allowsMultipleSelection = false
		panel.allowedContentTypes = [.application]

		guard panel.runModal() == .OK, let selectedURL = panel.url else { return }

		let application = TargetApplication.from(url: selectedURL)
		selectedApp = application
		statusText = "Selected app: \(application.displayName)."
		appStatusText = Self.statusText(for: application)
	}

	func saveSelectedAppAsDefault() {
		guard let selectedApp else {
			statusText = "Choose an app before saving a default."
			return
		}

		do {
			let bookmarkData = try selectedApp.url.bookmarkData(options: [], includingResourceValuesForKeys: nil, relativeTo: nil)
			UserDefaults.standard.set(bookmarkData, forKey: DefaultsKey.defaultAppBookmark)
			statusText = "Saved \(selectedApp.displayName) as the default app."
		} catch {
			statusText = "Failed to save the default app."
		}
	}

	func sanitizedCustomMinutes(_ value: String) -> String {
		String(value.filter(\.isNumber).prefix(3))
	}

	func applyCustomMinutesInput(_ value: String) {
		customMinutesText = sanitizedCustomMinutes(value)
	}

	func startTimerForCurrentSelection() {
		guard let option = selectedDelayOption() else { return }
		startTimer(using: option)
	}

	func startTimer(using option: DelayOption) {
		guard let selectedApp else {
			statusText = "Choose an app first."
			return
		}

		stopTimer()
		selectedOption = option
		activeDuration = option.seconds
		remainingSeconds = option.seconds
		phase = .running
		statusText = "\(selectedApp.displayName) will close in \(option.label)."
		appStatusText = Self.statusText(for: selectedApp)
		startTicking()
	}

	func cancelTimer(reason: String) {
		stopTimer()
		phase = .idle
		remainingSeconds = (resolvedDelayOption(fallbackToDefault: true) ?? defaultOption).seconds
		warningSecondsRemaining = 10
		statusText = reason
		appStatusText = Self.statusText(for: selectedApp)
	}

	func resetSelection() {
		durationSelectionMode = .preset
		selectedOption = defaultOption
		customMinutesText = ""
		remainingSeconds = selectedOption.seconds
		statusText = "Timer reset to the default 30 minutes."
		appStatusText = Self.statusText(for: selectedApp)
	}

	private func selectedDelayOption() -> DelayOption? {
		guard let option = resolvedDelayOption(fallbackToDefault: false) else {
			statusText = "Enter a custom duration between \(minimumCustomMinutes) and \(maximumCustomMinutes) minutes."
			return nil
		}

		return option
	}

	private func resolvedDelayOption(fallbackToDefault: Bool) -> DelayOption? {
		switch durationSelectionMode {
		case .preset:
			return selectedOption
		case .custom:
			guard let customMinutes = Int(customMinutesText),
				(minimumCustomMinutes...maximumCustomMinutes).contains(customMinutes) else {
				return fallbackToDefault ? defaultOption : nil
			}
			return DelayOption(minutes: customMinutes)
		}
	}

	private func startTicking() {
		countdownTask = Task { [weak self] in
			while !Task.isCancelled {
				try? await Task.sleep(for: .seconds(1))
				guard !Task.isCancelled else { break }
				self?.tick()
			}
		}
	}

	private func tick() {
		switch phase {
		case .idle:
			return
		case .running:
			remainingSeconds -= 1
			if remainingSeconds <= 0 {
				startWarningPhase()
			}
		case .warning:
			warningSecondsRemaining -= 1
			if warningSecondsRemaining <= 0 {
				closeSelectedAppNow(triggeredAutomatically: true)
			}
		}
	}

	private func startWarningPhase() {
		phase = .warning
		warningSecondsRemaining = 10
		statusText = "Time is up. Close \(selectedAppName), start a new timer, or cancel."
	}

	private func closeSelectedAppNow(triggeredAutomatically: Bool) {
		stopTimer()
		let appName = selectedAppName
		let didCloseSelectedApp = quitSelectedAppIfRunning()
		phase = .idle
		remainingSeconds = (resolvedDelayOption(fallbackToDefault: true) ?? defaultOption).seconds
		warningSecondsRemaining = 10
		if didCloseSelectedApp {
			statusText = triggeredAutomatically ? "\(appName) closed automatically." : "\(appName) closed."
			NSApp.activate(ignoringOtherApps: true)
		} else {
			statusText = "\(appName) was not running, so nothing needed to be closed."
		}
		appStatusText = Self.statusText(for: selectedApp)
	}

	private func stopTimer() {
		countdownTask?.cancel()
		countdownTask = nil
	}

	private func quitSelectedAppIfRunning() -> Bool {
		let runningApps = Self.runningApplications(for: selectedApp)
		guard !runningApps.isEmpty else { return false }
		for app in runningApps {
			app.terminate()
		}
		return true
	}

	private func format(seconds: Int) -> String {
		let minutes = max(seconds, 0) / 60
		let remainder = max(seconds, 0) % 60
		return String(format: "%02d:%02d", minutes, remainder)
	}

	private static func loadSavedDefaultApp() -> TargetApplication? {
		guard let bookmarkData = UserDefaults.standard.data(forKey: DefaultsKey.defaultAppBookmark) else {
			return nil
		}

		do {
			var isStale = false
			let url = try URL(
				resolvingBookmarkData: bookmarkData,
				options: [.withoutUI],
				relativeTo: nil,
				bookmarkDataIsStale: &isStale
			)

			if isStale {
				let refreshedBookmarkData = try url.bookmarkData(options: [], includingResourceValuesForKeys: nil, relativeTo: nil)
				UserDefaults.standard.set(refreshedBookmarkData, forKey: DefaultsKey.defaultAppBookmark)
			}

			return TargetApplication.from(url: url)
		} catch {
			return nil
		}
	}

	private static func runningApplications(for application: TargetApplication?) -> [NSRunningApplication] {
		guard let application else { return [] }

		if let bundleIdentifier = application.bundleIdentifier, !bundleIdentifier.isEmpty {
			return NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier)
		}

		return NSWorkspace.shared.runningApplications.filter { runningApplication in
			runningApplication.bundleURL?.standardizedFileURL == application.url.standardizedFileURL
		}
	}

	private static func statusText(for application: TargetApplication?) -> String {
		guard let application else { return "No app selected." }

		let isRunning = !runningApplications(for: application).isEmpty
		return isRunning
			? "\(application.displayName) is currently running and can be closed by the timer."
			: "\(application.displayName) is not running."
	}
}

struct ContentView: View {
	@StateObject private var viewModel = SleepTimerViewModel()

	var body: some View {
		VStack(alignment: .leading, spacing: 20) {
			Text("Sleep Timer")
				.font(.system(size: 28, weight: .bold, design: .rounded))

			HStack(alignment: .center, spacing: 16) {
				VStack(alignment: .leading, spacing: 8) {
					Text("Selected app")
						.font(.headline)
					HStack(spacing: 12) {
						Text(viewModel.selectedAppName)
							.font(.body.weight(.medium))
						Button("Choose App") {
							viewModel.chooseApp()
						}
						Button("Save as Default") {
							viewModel.saveSelectedAppAsDefault()
						}
						.disabled(!viewModel.hasSelectedApp)
					}

					Text("Close after")
						.font(.headline)
					Picker("Duration mode", selection: $viewModel.durationSelectionMode) {
						ForEach(DurationSelectionMode.allCases) { mode in
							Text(mode.label).tag(mode)
						}
					}
					.pickerStyle(.segmented)

					if viewModel.durationSelectionMode == .preset {
						Picker("Close after", selection: $viewModel.selectedOption) {
							ForEach(viewModel.options) { option in
								Text(option.label).tag(option)
							}
						}
						.labelsHidden()
						.pickerStyle(.segmented)
					} else {
						HStack(alignment: .firstTextBaseline, spacing: 12) {
							TextField(
								"Minutes",
								text: Binding(
									get: { viewModel.customMinutesText },
									set: { viewModel.applyCustomMinutesInput($0) }
								)
							)
							.textFieldStyle(.roundedBorder)
							.frame(width: 96)

							Text("minutes")
								.foregroundStyle(.secondary)
						}

						Text(viewModel.customMinutesHelpText)
							.font(.footnote)
							.foregroundStyle(.secondary)
					}
				}

				Spacer(minLength: 0)

				VStack(alignment: .trailing, spacing: 6) {
					Text(viewModel.progressLabel)
						.font(.title3.monospacedDigit())
					Text(viewModel.appStatusText)
						.font(.footnote)
						.foregroundStyle(.secondary)
						.multilineTextAlignment(.trailing)
				}
			}

			ProgressView(value: viewModel.progressValue, total: viewModel.progressTotal)
				.progressViewStyle(.linear)
				.controlSize(.large)

			Text(viewModel.statusText)
				.frame(maxWidth: .infinity, alignment: .leading)
				.padding(14)
				.background(
					RoundedRectangle(cornerRadius: 14)
						.fill(Color(nsColor: .textBackgroundColor))
				)

			HStack(spacing: 12) {
				Button(viewModel.primaryButtonTitle) {
					viewModel.primaryAction()
				}
				.disabled(!viewModel.hasSelectedApp && !viewModel.isRunning)
				.keyboardShortcut(.defaultAction)

				Button(viewModel.secondaryButtonTitle) {
					viewModel.secondaryAction()
				}

				if let tertiaryButtonTitle = viewModel.tertiaryButtonTitle {
					Button(tertiaryButtonTitle) {
						viewModel.tertiaryAction()
					}
				}

				Spacer(minLength: 0)
			}
		}
		.padding(24)
		.frame(minWidth: 640, idealWidth: 700, maxWidth: 760, minHeight: 340)
	}
}

@main
struct SleepTimerApp: App {
	var body: some Scene {
		WindowGroup {
			ContentView()
		}
		.windowResizability(.contentSize)
	}
}