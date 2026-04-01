import AppKit
import Foundation

let rootURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let outputURL = rootURL.appendingPathComponent("Support/AppIcon.icns")
let iconsetURL = rootURL.appendingPathComponent(".build/AppIcon.iconset")

let iconSizes: [(filename: String, pixels: Int)] = [
	("icon_16x16.png", 16),
	("icon_16x16@2x.png", 32),
	("icon_32x32.png", 32),
	("icon_32x32@2x.png", 64),
	("icon_128x128.png", 128),
	("icon_128x128@2x.png", 256),
	("icon_256x256.png", 256),
	("icon_256x256@2x.png", 512),
	("icon_512x512.png", 512),
	("icon_512x512@2x.png", 1024)
]

func rgba(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat = 1) -> NSColor {
	NSColor(srgbRed: red / 255, green: green / 255, blue: blue / 255, alpha: alpha)
}

func drawIcon(in rect: CGRect) {
	let canvas = rect.width
	let cornerRadius = canvas * 0.23
	let backgroundRect = rect.insetBy(dx: canvas * 0.03, dy: canvas * 0.03)
	let backgroundPath = NSBezierPath(roundedRect: backgroundRect, xRadius: cornerRadius, yRadius: cornerRadius)
	backgroundPath.addClip()

	let gradient = NSGradient(colors: [
		rgba(7, 13, 12),
		rgba(13, 24, 22),
		rgba(20, 36, 31)
	])!
	gradient.draw(in: backgroundPath, angle: -35)

	let glowRect = backgroundRect.insetBy(dx: canvas * 0.09, dy: canvas * 0.09)
	let glowGradient = NSGradient(
		colorsAndLocations:
		(rgba(108, 255, 195, 0.18), 0.0),
		(rgba(108, 255, 195, 0.04), 0.42),
		(rgba(0, 0, 0, 0.0), 1.0)
	)!
	glowGradient.draw(in: NSBezierPath(ovalIn: glowRect), relativeCenterPosition: NSPoint(x: 0, y: 0))

	let panelRect = backgroundRect.insetBy(dx: canvas * 0.12, dy: canvas * 0.16)
	let panelPath = NSBezierPath(roundedRect: panelRect, xRadius: canvas * 0.06, yRadius: canvas * 0.06)
	rgba(16, 27, 25, 0.98).setFill()
	panelPath.fill()

	panelPath.lineWidth = canvas * 0.01
	rgba(113, 221, 176, 0.35).setStroke()
	panelPath.stroke()

	let headerRect = CGRect(x: panelRect.minX, y: panelRect.maxY - canvas * 0.12, width: panelRect.width, height: canvas * 0.09)
	let headerPath = NSBezierPath(roundedRect: headerRect, xRadius: canvas * 0.04, yRadius: canvas * 0.04)
	rgba(21, 37, 34, 1).setFill()
	headerPath.fill()

	let dotY = headerRect.midY
	let dotRadius = canvas * 0.015
	for (index, color) in [rgba(255, 95, 86), rgba(255, 189, 46), rgba(39, 201, 63)].enumerated() {
		color.setFill()
		let x = headerRect.minX + canvas * 0.05 + CGFloat(index) * canvas * 0.035
		NSBezierPath(ovalIn: CGRect(x: x, y: dotY - dotRadius, width: dotRadius * 2, height: dotRadius * 2)).fill()
	}

	let promptFont = NSFont.monospacedSystemFont(ofSize: canvas * 0.11, weight: .bold)
	let commandFont = NSFont.monospacedSystemFont(ofSize: canvas * 0.18, weight: .bold)
	let metricsFont = NSFont.monospacedSystemFont(ofSize: canvas * 0.075, weight: .medium)

	let promptAttributes: [NSAttributedString.Key: Any] = [
		.font: promptFont,
		.foregroundColor: rgba(108, 255, 195, 1)
	]
	let commandAttributes: [NSAttributedString.Key: Any] = [
		.font: commandFont,
		.foregroundColor: rgba(244, 255, 249, 1)
	]
	let metricsAttributes: [NSAttributedString.Key: Any] = [
		.font: metricsFont,
		.foregroundColor: rgba(142, 189, 170, 0.88)
	]

	NSAttributedString(string: "> ready", attributes: promptAttributes).draw(at: CGPoint(x: panelRect.minX + canvas * 0.08, y: panelRect.minY + canvas * 0.54))
	NSAttributedString(string: "_", attributes: promptAttributes).draw(at: CGPoint(x: panelRect.minX + canvas * 0.62, y: panelRect.minY + canvas * 0.54))
	NSAttributedString(string: "sleep", attributes: commandAttributes).draw(at: CGPoint(x: panelRect.minX + canvas * 0.17, y: panelRect.minY + canvas * 0.33))
	NSAttributedString(string: "30m", attributes: metricsAttributes).draw(at: CGPoint(x: panelRect.minX + canvas * 0.20, y: panelRect.minY + canvas * 0.18))

	let progressTrackRect = CGRect(x: panelRect.minX + canvas * 0.20, y: panelRect.minY + canvas * 0.12, width: panelRect.width * 0.58, height: canvas * 0.028)
	let progressTrack = NSBezierPath(roundedRect: progressTrackRect, xRadius: progressTrackRect.height / 2, yRadius: progressTrackRect.height / 2)
	rgba(52, 71, 65, 1).setFill()
	progressTrack.fill()

	let progressFillRect = CGRect(x: progressTrackRect.minX, y: progressTrackRect.minY, width: progressTrackRect.width * 0.56, height: progressTrackRect.height)
	let progressFill = NSBezierPath(roundedRect: progressFillRect, xRadius: progressFillRect.height / 2, yRadius: progressFillRect.height / 2)
	rgba(108, 255, 195, 1).setFill()
	progressFill.fill()

	for index in 0..<7 {
		let y = panelRect.minY + canvas * 0.11 + CGFloat(index) * canvas * 0.055
		let line = NSBezierPath()
		line.move(to: CGPoint(x: panelRect.minX + canvas * 0.045, y: y))
		line.line(to: CGPoint(x: panelRect.maxX - canvas * 0.045, y: y))
		line.lineWidth = canvas * 0.003
		rgba(108, 255, 195, index == 2 ? 0.09 : 0.04).setStroke()
		line.stroke()
	}

	let borderPath = NSBezierPath(roundedRect: backgroundRect, xRadius: cornerRadius, yRadius: cornerRadius)
	borderPath.lineWidth = canvas * 0.012
	rgba(255, 255, 255, 0.08).setStroke()
	borderPath.stroke()
}

func pngData(size: Int) throws -> Data {
	let bitmap = NSBitmapImageRep(
		bitmapDataPlanes: nil,
		pixelsWide: size,
		pixelsHigh: size,
		bitsPerSample: 8,
		samplesPerPixel: 4,
		hasAlpha: true,
		isPlanar: false,
		colorSpaceName: .deviceRGB,
		bytesPerRow: 0,
		bitsPerPixel: 0
	)!

	NSGraphicsContext.saveGraphicsState()
	let context = NSGraphicsContext(bitmapImageRep: bitmap)!
	NSGraphicsContext.current = context

	NSColor.clear.setFill()
	NSBezierPath(rect: CGRect(x: 0, y: 0, width: size, height: size)).fill()
	drawIcon(in: CGRect(x: 0, y: 0, width: size, height: size))
	context.flushGraphics()
	NSGraphicsContext.restoreGraphicsState()

	guard let data = bitmap.representation(using: .png, properties: [:]) else {
		throw NSError(domain: "IconGeneration", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode PNG data."])
	}
	return data
}

let fileManager = FileManager.default
try? fileManager.removeItem(at: iconsetURL)
try fileManager.createDirectory(at: iconsetURL, withIntermediateDirectories: true)

for icon in iconSizes {
	let data = try pngData(size: icon.pixels)
	try data.write(to: iconsetURL.appendingPathComponent(icon.filename))
}

let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = ["-c", "icns", iconsetURL.path, "-o", outputURL.path]
try process.run()
process.waitUntilExit()

guard process.terminationStatus == 0 else {
	throw NSError(domain: "IconGeneration", code: Int(process.terminationStatus), userInfo: [NSLocalizedDescriptionKey: "iconutil failed with exit code \(process.terminationStatus)."])
}

print("Created \(outputURL.path)")