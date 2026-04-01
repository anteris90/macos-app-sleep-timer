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

enum ConsoleThemeOption: String, CaseIterable, Identifiable {
	static let defaultsKey = "selectedTheme"

	case green
	case red

	var id: String { rawValue }

	var label: String {
		switch self {
		case .green:
			return "Green"
		case .red:
			return "Red"
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
	@AppStorage(ConsoleThemeOption.defaultsKey) private var selectedThemeRawValue = ConsoleThemeOption.green.rawValue

	var body: some View {
		ZStack {
			LinearGradient(
				colors: [ConsolePalette.backgroundTop, ConsolePalette.backgroundBottom],
				startPoint: .topLeading,
				endPoint: .bottomTrailing
			)
			.ignoresSafeArea()

			ConsoleGrid()
				.opacity(0.14)
				.ignoresSafeArea()

			VStack(alignment: .leading, spacing: 18) {
				HStack(alignment: .top) {
					VStack(alignment: .leading, spacing: 6) {
						Text("sleep-timer>")
							.font(.system(size: 13, weight: .semibold, design: .monospaced))
							.foregroundStyle(ConsolePalette.accent)

						Text("Sleep Timer")
							.font(.system(size: 28, weight: .bold, design: .monospaced))
							.foregroundStyle(ConsolePalette.textPrimary)

						Text("A focused timer panel for gracefully closing one selected app.")
							.font(.system(size: 12, weight: .regular, design: .monospaced))
							.foregroundStyle(ConsolePalette.textSecondary)
					}

					Spacer(minLength: 0)

					Text(viewModel.isRunning ? "LIVE" : "IDLE")
						.font(.system(size: 11, weight: .bold, design: .monospaced))
						.padding(.horizontal, 10)
						.padding(.vertical, 6)
						.background(
							Capsule()
								.fill(viewModel.isRunning ? ConsolePalette.accent.opacity(0.22) : ConsolePalette.panelHighlight)
						)
						.overlay(
							Capsule()
								.stroke(viewModel.isRunning ? ConsolePalette.accent : ConsolePalette.border, lineWidth: 1)
						)
						.foregroundStyle(viewModel.isRunning ? ConsolePalette.accent : ConsolePalette.textSecondary)
				}
				.frame(maxWidth: .infinity, alignment: .leading)

				VStack(alignment: .leading, spacing: 16) {
					selectedAppPanel
						.frame(maxWidth: .infinity)

					monitorPanel
						.frame(maxWidth: .infinity)
				}
				.frame(maxWidth: .infinity)

				consolePanel {
					VStack(alignment: .leading, spacing: 10) {
						consoleSectionLabel("Console output")
						Text(viewModel.statusText)
							.font(.system(size: 13, weight: .regular, design: .monospaced))
							.foregroundStyle(ConsolePalette.textPrimary)
							.frame(maxWidth: .infinity, alignment: .leading)
					}
				}
				.frame(maxWidth: .infinity, alignment: .leading)

				HStack(spacing: 12) {
					Button(viewModel.primaryButtonTitle) {
						viewModel.primaryAction()
					}
					.buttonStyle(ConsoleButtonStyle(role: .primary))
					.disabled(!viewModel.hasSelectedApp && !viewModel.isRunning)
					.keyboardShortcut(.defaultAction)

					Button(viewModel.secondaryButtonTitle) {
						viewModel.secondaryAction()
					}
					.buttonStyle(ConsoleButtonStyle(role: .standard))

					if let tertiaryButtonTitle = viewModel.tertiaryButtonTitle {
						Button(tertiaryButtonTitle) {
							viewModel.tertiaryAction()
						}
						.buttonStyle(ConsoleButtonStyle(role: .standard))
					}

					Spacer(minLength: 0)
				}
				.frame(maxWidth: .infinity, alignment: .leading)
			}
			.padding(24)
		}
		.id(selectedThemeRawValue)
		.frame(width: 820, height: 720)
	}

	private func consolePanel<Content: View>(@ViewBuilder content: () -> Content) -> some View {
		content()
			.padding(16)
			.frame(maxWidth: .infinity, alignment: .topLeading)
			.background(
				RoundedRectangle(cornerRadius: 16)
					.fill(ConsolePalette.panel)
			)
			.overlay(
				RoundedRectangle(cornerRadius: 16)
					.stroke(ConsolePalette.border, lineWidth: 1)
			)
	}

	private var selectedAppPanel: some View {
		consolePanel {
			VStack(alignment: .leading, spacing: 14) {
				HStack(alignment: .center, spacing: 10) {
					consoleSectionLabel("Selected app")
					appBadge(viewModel.selectedAppName)
					Spacer(minLength: 0)
				}

				consoleSegmentedControl {
					Button("Choose App") {
						viewModel.chooseApp()
					}
					.buttonStyle(ConsoleSegmentButtonStyle(isSelected: false, size: .regular))

					Button("Save as Default") {
						viewModel.saveSelectedAppAsDefault()
					}
					.buttonStyle(ConsoleSegmentButtonStyle(isSelected: false, size: .regular))
					.disabled(!viewModel.hasSelectedApp)
				}

				Divider()
					.overlay(ConsolePalette.border)

				consoleSectionLabel("Close after")
				consoleSegmentedControl {
					ForEach(DurationSelectionMode.allCases) { mode in
						Button(mode.label) {
							viewModel.durationSelectionMode = mode
						}
						.buttonStyle(ConsoleSegmentButtonStyle(isSelected: viewModel.durationSelectionMode == mode, size: .regular))
					}
				}

				if viewModel.durationSelectionMode == .preset {
					consoleSegmentedControl(size: .regular) {
						ForEach(viewModel.options) { option in
							Button(option.label) {
								viewModel.selectedOption = option
							}
							.buttonStyle(ConsoleSegmentButtonStyle(isSelected: viewModel.selectedOption == option, size: .regular))
						}
					}
				} else {
					HStack(alignment: .center, spacing: 12) {
						TextField(
							"Minutes",
							text: Binding(
								get: { viewModel.customMinutesText },
								set: { viewModel.applyCustomMinutesInput($0) }
							)
						)
							.textFieldStyle(.plain)
							.font(.system(size: 14, weight: .medium, design: .monospaced))
							.foregroundStyle(ConsolePalette.textPrimary)
							.frame(width: 96)
							.padding(.horizontal, 10)
							.padding(.vertical, 8)
							.background(
								RoundedRectangle(cornerRadius: 8)
									.fill(ConsolePalette.panelInset)
							)
							.overlay(
								RoundedRectangle(cornerRadius: 8)
									.stroke(ConsolePalette.border, lineWidth: 1)
							)

						Text("minutes")
							.font(.system(size: 12, weight: .regular, design: .monospaced))
							.foregroundStyle(ConsolePalette.textSecondary)
					}

					Text(viewModel.customMinutesHelpText)
						.font(.system(size: 11, weight: .regular, design: .monospaced))
						.foregroundStyle(ConsolePalette.textSecondary)
				}
			}
		}
		.frame(minHeight: 272, maxHeight: 272, alignment: .topLeading)
	}

	private var monitorPanel: some View {
		consolePanel {
			VStack(alignment: .leading, spacing: 14) {
				consoleSectionLabel("Monitor")

				Text(viewModel.progressLabel)
					.font(.system(size: 20, weight: .semibold, design: .monospaced))
					.foregroundStyle(ConsolePalette.textPrimary)

				Text(viewModel.appStatusText)
					.font(.system(size: 12, weight: .regular, design: .monospaced))
					.foregroundStyle(ConsolePalette.textSecondary)
					.lineLimit(3)
					.fixedSize(horizontal: false, vertical: true)

				VStack(alignment: .leading, spacing: 8) {
					Text("progress")
						.font(.system(size: 11, weight: .semibold, design: .monospaced))
						.foregroundStyle(ConsolePalette.textSecondary)

					ProgressView(value: viewModel.progressValue, total: viewModel.progressTotal)
						.progressViewStyle(.linear)
						.tint(ConsolePalette.accent)
						.controlSize(.large)
				}
			}
			.frame(maxWidth: .infinity, alignment: .leading)
		}
		.frame(minHeight: 180, maxHeight: 180, alignment: .topLeading)
	}

	private func consoleSectionLabel(_ text: String) -> some View {
		Text(text.uppercased())
			.font(.system(size: 11, weight: .bold, design: .monospaced))
			.foregroundStyle(ConsolePalette.textSecondary)
	}

	private func appBadge(_ text: String) -> some View {
		Text(text)
			.font(.system(size: 11, weight: .semibold, design: .monospaced))
			.foregroundStyle(ConsolePalette.textPrimary)
			.lineLimit(1)
			.padding(.horizontal, 10)
			.padding(.vertical, 5)
			.background(
				Capsule()
					.fill(ConsolePalette.panelInset)
			)
			.overlay(
				Capsule()
					.stroke(ConsolePalette.border, lineWidth: 1)
			)
	}

	private func consoleSegmentedControl<Content: View>(size: ConsoleSegmentButtonStyle.Size = .regular, @ViewBuilder content: () -> Content) -> some View {
		HStack(spacing: 0) {
			content()
		}
		.padding(size == .regular ? 4 : 3)
		.background(
			RoundedRectangle(cornerRadius: size == .regular ? 11 : 10)
				.fill(ConsolePalette.panelInset)
		)
		.overlay(
			RoundedRectangle(cornerRadius: size == .regular ? 11 : 10)
				.stroke(ConsolePalette.border, lineWidth: 1)
		)
	}
}

private enum ConsolePalette {
	private static var theme: ConsoleThemeOption {
		ConsoleThemeOption(
			rawValue: UserDefaults.standard.string(forKey: ConsoleThemeOption.defaultsKey) ?? ConsoleThemeOption.green.rawValue
		) ?? .green
	}

	static var backgroundTop: Color {
		switch theme {
		case .green:
			return Color(nsColor: NSColor(calibratedRed: 0.06, green: 0.08, blue: 0.07, alpha: 1))
		case .red:
			return Color(nsColor: NSColor(calibratedRed: 0.09, green: 0.06, blue: 0.06, alpha: 1))
		}
	}

	static var backgroundBottom: Color {
		switch theme {
		case .green:
			return Color(nsColor: NSColor(calibratedRed: 0.03, green: 0.04, blue: 0.04, alpha: 1))
		case .red:
			return Color(nsColor: NSColor(calibratedRed: 0.04, green: 0.03, blue: 0.03, alpha: 1))
		}
	}

	static var panel: Color {
		switch theme {
		case .green:
			return Color(nsColor: NSColor(calibratedRed: 0.10, green: 0.12, blue: 0.11, alpha: 0.94))
		case .red:
			return Color(nsColor: NSColor(calibratedRed: 0.13, green: 0.11, blue: 0.11, alpha: 0.94))
		}
	}

	static var panelInset: Color {
		switch theme {
		case .green:
			return Color(nsColor: NSColor(calibratedRed: 0.07, green: 0.08, blue: 0.08, alpha: 1))
		case .red:
			return Color(nsColor: NSColor(calibratedRed: 0.09, green: 0.07, blue: 0.07, alpha: 1))
		}
	}

	static var panelHighlight: Color {
		switch theme {
		case .green:
			return Color(nsColor: NSColor(calibratedRed: 0.16, green: 0.18, blue: 0.17, alpha: 0.92))
		case .red:
			return Color(nsColor: NSColor(calibratedRed: 0.20, green: 0.15, blue: 0.15, alpha: 0.92))
		}
	}

	static var border: Color {
		switch theme {
		case .green:
			return Color(nsColor: NSColor(calibratedRed: 0.24, green: 0.30, blue: 0.27, alpha: 1))
		case .red:
			return Color(nsColor: NSColor(calibratedRed: 0.36, green: 0.24, blue: 0.24, alpha: 1))
		}
	}

	static var accent: Color {
		switch theme {
		case .green:
			return Color(nsColor: NSColor(calibratedRed: 0.39, green: 0.92, blue: 0.63, alpha: 1))
		case .red:
			return Color(nsColor: NSColor(calibratedRed: 0.95, green: 0.42, blue: 0.42, alpha: 1))
		}
	}

	static var accentPressed: Color {
		switch theme {
		case .green:
			return Color(nsColor: NSColor(calibratedRed: 0.29, green: 0.74, blue: 0.50, alpha: 1))
		case .red:
			return Color(nsColor: NSColor(calibratedRed: 0.78, green: 0.31, blue: 0.31, alpha: 1))
		}
	}

	static var textPrimary: Color {
		Color(nsColor: NSColor(calibratedRed: 0.90, green: 0.96, blue: 0.92, alpha: 1))
	}

	static var textSecondary: Color {
		switch theme {
		case .green:
			return Color(nsColor: NSColor(calibratedRed: 0.60, green: 0.72, blue: 0.65, alpha: 1))
		case .red:
			return Color(nsColor: NSColor(calibratedRed: 0.74, green: 0.64, blue: 0.64, alpha: 1))
		}
	}

	static var disabled: Color {
		switch theme {
		case .green:
			return Color(nsColor: NSColor(calibratedRed: 0.35, green: 0.41, blue: 0.38, alpha: 1))
		case .red:
			return Color(nsColor: NSColor(calibratedRed: 0.44, green: 0.35, blue: 0.35, alpha: 1))
		}
	}
}

private enum ConsoleTypography {
	static let controlFont = Font.system(size: 12, weight: .semibold, design: .monospaced)
}

private struct ConsoleGrid: View {
	var body: some View {
		GeometryReader { geometry in
			Path { path in
				let spacing: CGFloat = 24

				stride(from: CGFloat.zero, through: geometry.size.width, by: spacing).forEach { x in
					path.move(to: CGPoint(x: x, y: 0))
					path.addLine(to: CGPoint(x: x, y: geometry.size.height))
				}

				stride(from: CGFloat.zero, through: geometry.size.height, by: spacing).forEach { y in
					path.move(to: CGPoint(x: 0, y: y))
					path.addLine(to: CGPoint(x: geometry.size.width, y: y))
				}
			}
			.stroke(ConsolePalette.border.opacity(0.35), lineWidth: 0.5)
		}
	}
}

private struct ConsoleButtonStyle: ButtonStyle {
	enum Role {
		case primary
		case standard
	}

	let role: Role
	let minWidth: CGFloat

	init(role: Role, minWidth: CGFloat? = nil) {
		self.role = role
		self.minWidth = minWidth ?? (role == .primary ? 92 : 104)
	}

	func makeBody(configuration: Configuration) -> some View {
		configuration.label
			.font(ConsoleTypography.controlFont)
			.foregroundStyle(foregroundColor(isPressed: configuration.isPressed))
			.frame(minWidth: minWidth)
			.padding(.horizontal, 14)
			.padding(.vertical, 9)
			.background(
				RoundedRectangle(cornerRadius: 10)
					.fill(backgroundColor(isPressed: configuration.isPressed))
			)
			.overlay(
				RoundedRectangle(cornerRadius: 10)
					.stroke(borderColor(isPressed: configuration.isPressed), lineWidth: 1)
			)
			.opacity(configuration.isPressed ? 0.92 : 1)
	}

	private func backgroundColor(isPressed: Bool) -> Color {
		switch role {
		case .primary:
			return isPressed ? ConsolePalette.accentPressed.opacity(0.28) : ConsolePalette.accent.opacity(0.18)
		case .standard:
			return isPressed ? ConsolePalette.panelHighlight : ConsolePalette.panelInset
		}
	}

	private func borderColor(isPressed: Bool) -> Color {
		switch role {
		case .primary:
			return isPressed ? ConsolePalette.accentPressed : ConsolePalette.accent
		case .standard:
			return ConsolePalette.border
		}
	}

	private func foregroundColor(isPressed: Bool) -> Color {
		switch role {
		case .primary:
			return isPressed ? ConsolePalette.textPrimary.opacity(0.9) : ConsolePalette.accent
		case .standard:
			return ConsolePalette.textPrimary
		}
	}
}

private struct ConsoleSegmentButtonStyle: ButtonStyle {
	enum Size {
		case regular
		case compact
	}

	let isSelected: Bool
	let size: Size

	func makeBody(configuration: Configuration) -> some View {
		configuration.label
			.font(font)
			.foregroundStyle(foregroundColor(isPressed: configuration.isPressed))
			.lineLimit(1)
			.minimumScaleFactor(minimumScaleFactor)
			.allowsTightening(allowsTightening)
			.frame(maxWidth: .infinity)
			.padding(.horizontal, horizontalPadding)
			.padding(.vertical, verticalPadding)
			.background(
				RoundedRectangle(cornerRadius: cornerRadius)
					.fill(backgroundColor(isPressed: configuration.isPressed))
			)
			.contentShape(RoundedRectangle(cornerRadius: cornerRadius))
	}

	private var font: Font {
		switch size {
		case .regular:
			return ConsoleTypography.controlFont
		case .compact:
			return .system(size: 11, weight: .semibold, design: .monospaced)
		}
	}

	private var horizontalPadding: CGFloat {
		switch size {
		case .regular:
			return 14
		case .compact:
			return 5
		}
	}

	private var minimumScaleFactor: CGFloat {
		switch size {
		case .regular:
			return 1
		case .compact:
			return 0.75
		}
	}

	private var allowsTightening: Bool {
		switch size {
		case .regular:
			return false
		case .compact:
			return true
		}
	}

	private var verticalPadding: CGFloat {
		switch size {
		case .regular:
			return 10
		case .compact:
			return 6
		}
	}

	private var cornerRadius: CGFloat {
		switch size {
		case .regular:
			return 8
		case .compact:
			return 7
		}
	}

	private func backgroundColor(isPressed: Bool) -> Color {
		if isSelected {
			return isPressed ? ConsolePalette.accentPressed.opacity(0.35) : ConsolePalette.accent.opacity(0.22)
		}

		return isPressed ? ConsolePalette.panelHighlight : .clear
	}

	private func foregroundColor(isPressed: Bool) -> Color {
		if isSelected {
			return isPressed ? ConsolePalette.textPrimary.opacity(0.9) : ConsolePalette.accent
		}

		return isPressed ? ConsolePalette.textPrimary : ConsolePalette.textSecondary
	}
}


@main
struct SleepTimerApp: App {
	@AppStorage(ConsoleThemeOption.defaultsKey) private var selectedThemeRawValue = ConsoleThemeOption.green.rawValue

	var body: some Scene {
		WindowGroup {
			ContentView()
		}
		.windowResizability(.contentSize)
		.commands {
			CommandMenu("Theme") {
				Picker("Theme", selection: $selectedThemeRawValue) {
					ForEach(ConsoleThemeOption.allCases) { theme in
						Text(theme.label).tag(theme.rawValue)
					}
				}
			}
		}
	}
}