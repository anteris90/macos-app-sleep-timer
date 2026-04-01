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
		rgba(25, 12, 16),
		rgba(31, 14, 18),
		rgba(42, 17, 20)
	])!
	gradient.draw(in: backgroundPath, angle: -45)

	let glowRect = backgroundRect.insetBy(dx: canvas * 0.08, dy: canvas * 0.08)
	let glowGradient = NSGradient(
		colorsAndLocations:
		(rgba(255, 126, 90, 0.16), 0.0),
		(rgba(255, 126, 90, 0.04), 0.45),
		(rgba(0, 0, 0, 0.0), 1.0)
	)!
	glowGradient.draw(in: NSBezierPath(ovalIn: glowRect), relativeCenterPosition: NSPoint(x: 0, y: 0))

	let faceColor = rgba(179, 66, 62, 0.86)
	let highlightColor = rgba(233, 86, 77, 0.96)
	let moonColor = rgba(255, 129, 54, 1)

	let clockCenter = CGPoint(x: canvas * 0.46, y: canvas * 0.50)
	let clockRadius = canvas * 0.225
	let ringRect = CGRect(x: clockCenter.x - clockRadius, y: clockCenter.y - clockRadius, width: clockRadius * 2, height: clockRadius * 2)
	let ringPath = NSBezierPath(ovalIn: ringRect)
	ringPath.lineWidth = canvas * 0.028
	faceColor.setStroke()
	ringPath.stroke()

	let topButtonRect = CGRect(x: clockCenter.x - canvas * 0.05, y: ringRect.maxY + canvas * 0.02, width: canvas * 0.10, height: canvas * 0.042)
	let topButtonPath = NSBezierPath(roundedRect: topButtonRect, xRadius: canvas * 0.02, yRadius: canvas * 0.02)
	faceColor.setFill()
	topButtonPath.fill()

	let sideButtonRect = CGRect(x: ringRect.minX + canvas * 0.01, y: ringRect.maxY - canvas * 0.015, width: canvas * 0.07, height: canvas * 0.04)
	let sideButtonPath = NSBezierPath(roundedRect: sideButtonRect, xRadius: canvas * 0.018, yRadius: canvas * 0.018)
	sideButtonPath.transform(using: AffineTransform(rotationByDegrees: 35))
	faceColor.setFill()
	sideButtonPath.fill()

	for tick in 0..<12 {
		let angle = CGFloat(tick) * (.pi * 2 / 12)
		let outer = CGPoint(x: clockCenter.x + cos(angle - .pi / 2) * clockRadius * 0.78, y: clockCenter.y + sin(angle - .pi / 2) * clockRadius * 0.78)
		let inner = CGPoint(x: clockCenter.x + cos(angle - .pi / 2) * clockRadius * 0.62, y: clockCenter.y + sin(angle - .pi / 2) * clockRadius * 0.62)
		let tickPath = NSBezierPath()
		tickPath.move(to: inner)
		tickPath.line(to: outer)
		tickPath.lineWidth = canvas * 0.015
		tickPath.lineCapStyle = .round
		faceColor.setStroke()
		tickPath.stroke()
	}

	let handPath = NSBezierPath()
	handPath.move(to: clockCenter)
	handPath.line(to: CGPoint(x: clockCenter.x - canvas * 0.07, y: clockCenter.y + canvas * 0.05))
	handPath.move(to: clockCenter)
	handPath.line(to: CGPoint(x: clockCenter.x + canvas * 0.09, y: clockCenter.y + canvas * 0.065))
	handPath.lineWidth = canvas * 0.022
	handPath.lineCapStyle = .round
	handPath.lineJoinStyle = .round
	highlightColor.setStroke()
	handPath.stroke()

	rgba(113, 33, 35).setFill()
	NSBezierPath(ovalIn: CGRect(x: clockCenter.x - canvas * 0.026, y: clockCenter.y - canvas * 0.026, width: canvas * 0.052, height: canvas * 0.052)).fill()
	highlightColor.setFill()
	NSBezierPath(ovalIn: CGRect(x: clockCenter.x - canvas * 0.013, y: clockCenter.y - canvas * 0.013, width: canvas * 0.026, height: canvas * 0.026)).fill()

	let moonRect = CGRect(x: canvas * 0.50, y: canvas * 0.30, width: canvas * 0.22, height: canvas * 0.28)
	moonColor.setFill()
	NSBezierPath(ovalIn: moonRect).fill()

	let moonCutoutRect = moonRect.offsetBy(dx: canvas * 0.06, dy: canvas * 0.01)
	rgba(31, 14, 18).setFill()
	NSBezierPath(ovalIn: moonCutoutRect).fill()

	func drawStar(at center: CGPoint, radius: CGFloat) {
		let star = NSBezierPath()
		star.move(to: CGPoint(x: center.x, y: center.y + radius))
		star.line(to: CGPoint(x: center.x + radius * 0.35, y: center.y + radius * 0.35))
		star.line(to: CGPoint(x: center.x + radius, y: center.y))
		star.line(to: CGPoint(x: center.x + radius * 0.35, y: center.y - radius * 0.35))
		star.line(to: CGPoint(x: center.x, y: center.y - radius))
		star.line(to: CGPoint(x: center.x - radius * 0.35, y: center.y - radius * 0.35))
		star.line(to: CGPoint(x: center.x - radius, y: center.y))
		star.line(to: CGPoint(x: center.x - radius * 0.35, y: center.y + radius * 0.35))
		star.close()
		moonColor.setFill()
		star.fill()
	}

	drawStar(at: CGPoint(x: canvas * 0.70, y: canvas * 0.46), radius: canvas * 0.028)
	drawStar(at: CGPoint(x: canvas * 0.77, y: canvas * 0.56), radius: canvas * 0.022)
	drawStar(at: CGPoint(x: canvas * 0.64, y: canvas * 0.40), radius: canvas * 0.020)

	let zFontLarge = NSFont.monospacedSystemFont(ofSize: canvas * 0.11, weight: .bold)
	let zFontMedium = NSFont.monospacedSystemFont(ofSize: canvas * 0.095, weight: .bold)
	let zFontSmall = NSFont.monospacedSystemFont(ofSize: canvas * 0.08, weight: .bold)
	let zAttributes: [NSAttributedString.Key: Any] = [
		.foregroundColor: highlightColor
	]
	NSAttributedString(string: "Z", attributes: zAttributes.merging([.font: zFontLarge]) { $1 }).draw(at: CGPoint(x: canvas * 0.69, y: canvas * 0.66))
	NSAttributedString(string: "Z", attributes: zAttributes.merging([.font: zFontMedium]) { $1 }).draw(at: CGPoint(x: canvas * 0.79, y: canvas * 0.74))
	NSAttributedString(string: "Z", attributes: zAttributes.merging([.font: zFontSmall]) { $1 }).draw(at: CGPoint(x: canvas * 0.86, y: canvas * 0.80))

	let borderPath = NSBezierPath(roundedRect: backgroundRect, xRadius: cornerRadius, yRadius: cornerRadius)
	borderPath.lineWidth = canvas * 0.012
	rgba(205, 88, 80, 0.42).setStroke()
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