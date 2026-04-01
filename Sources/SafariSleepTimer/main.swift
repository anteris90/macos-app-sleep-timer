import AppKit
import SwiftUI

struct DelayOption: Identifiable, Hashable {
	let minutes: Int

	var id: Int { minutes }
	var label: String { "\(minutes) min" }
	var seconds: Int { minutes * 60 }
}

enum TimerPhase {
	case idle
	case running
	case warning
}

@MainActor
final class SleepTimerViewModel: ObservableObject {
	let options = [15, 30, 45, 60, 90].map(DelayOption.init)

	@Published var selectedOption: DelayOption
	@Published var phase: TimerPhase = .idle
	@Published var activeDuration: Int = 0
	@Published var remainingSeconds: Int = 0
	@Published var warningSecondsRemaining: Int = 10
	@Published var statusText = "Choose a duration, then start the timer."
	@Published var safariStatusText = "Safari is not scheduled to close."

	private var countdownTask: Task<Void, Never>?

	init() {
		let defaultOption = DelayOption(minutes: 30)
		selectedOption = defaultOption
		remainingSeconds = defaultOption.seconds
	}

	deinit {
		countdownTask?.cancel()
	}

	var isRunning: Bool {
		phase == .running || phase == .warning
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
			return "Closing Safari in: \(warningSecondsRemaining)s"
		}
	}

	func primaryAction() {
		switch phase {
		case .idle:
			startTimer(using: selectedOption)
		case .running:
			startTimer(using: selectedOption)
		case .warning:
			closeSafariNow(triggeredAutomatically: false)
		}
	}

	func secondaryAction() {
		switch phase {
		case .idle:
			resetSelection()
		case .running:
			cancelTimer(reason: "Az időzítés leállítva.")
		case .warning:
			startTimer(using: selectedOption)
		}
	}

	func tertiaryAction() {
		guard phase == .warning else { return }
		cancelTimer(reason: "Safari close cancelled.")
	}

	func startTimer(using option: DelayOption) {
		stopTimer()
		selectedOption = option
		activeDuration = option.seconds
		remainingSeconds = option.seconds
		phase = .running
		statusText = "Safari close scheduled for \(option.label)."
		safariStatusText = safariRunningStatusText()
		startTicking()
	}

	func cancelTimer(reason: String) {
		stopTimer()
		phase = .idle
		remainingSeconds = selectedOption.seconds
		warningSecondsRemaining = 10
		statusText = reason
		safariStatusText = safariRunningStatusText()
	}

	func resetSelection() {
		selectedOption = DelayOption(minutes: 30)
		remainingSeconds = selectedOption.seconds
		statusText = "Timer reset to the default 30 minutes."
		safariStatusText = safariRunningStatusText()
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
				closeSafariNow(triggeredAutomatically: true)
			}
		}
	}

	private func startWarningPhase() {
		phase = .warning
		warningSecondsRemaining = 10
		statusText = "Time is up. Choose to close Safari, start a new timer, or cancel."
	}

	private func closeSafariNow(triggeredAutomatically: Bool) {
		stopTimer()
		let didCloseSafari = quitSafariIfRunning()
		phase = .idle
		remainingSeconds = selectedOption.seconds
		warningSecondsRemaining = 10
		if didCloseSafari {
			statusText = triggeredAutomatically ? "Safari closed automatically." : "Safari closed."
			NSApp.activate(ignoringOtherApps: true)
		} else {
			statusText = "Safari was not running, so nothing needed to be closed."
		}
		safariStatusText = safariRunningStatusText()
	}

	private func stopTimer() {
		countdownTask?.cancel()
		countdownTask = nil
	}

	private func quitSafariIfRunning() -> Bool {
		let safariApps = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.Safari")
		guard !safariApps.isEmpty else { return false }
		for app in safariApps {
			app.terminate()
		}
		return true
	}

	private func safariRunningStatusText() -> String {
		let isSafariRunning = !NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.Safari").isEmpty
		return isSafariRunning ? "Safari is currently running and can be closed by the timer." : "Safari is not running."
	}

	private func format(seconds: Int) -> String {
		let minutes = max(seconds, 0) / 60
		let remainder = max(seconds, 0) % 60
		return String(format: "%02d:%02d", minutes, remainder)
	}
}

struct ContentView: View {
	@StateObject private var viewModel = SleepTimerViewModel()

	var body: some View {
		VStack(alignment: .leading, spacing: 20) {
			Text("Safari Sleep Timer")
				.font(.system(size: 28, weight: .bold, design: .rounded))

			HStack(alignment: .center, spacing: 16) {
				VStack(alignment: .leading, spacing: 8) {
					Text("Close after")
						.font(.headline)
					Picker("Close after", selection: $viewModel.selectedOption) {
						ForEach(viewModel.options) { option in
							Text(option.label).tag(option)
						}
					}
					.labelsHidden()
					.pickerStyle(.segmented)
				}

				Spacer(minLength: 0)

				VStack(alignment: .trailing, spacing: 6) {
					Text(viewModel.progressLabel)
						.font(.title3.monospacedDigit())
					Text(viewModel.safariStatusText)
						.font(.footnote)
						.foregroundStyle(.secondary)
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
		.frame(minWidth: 640, idealWidth: 700, maxWidth: 760, minHeight: 300)
	}
}

@main
struct SafariSleepTimerApp: App {
	var body: some Scene {
		WindowGroup {
			ContentView()
		}
		.windowResizability(.contentSize)
	}
}