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
	let cornerRadius = canvas * 0.225
	let backgroundRect = rect.insetBy(dx: canvas * 0.03, dy: canvas * 0.03)
	let backgroundPath = NSBezierPath(roundedRect: backgroundRect, xRadius: cornerRadius, yRadius: cornerRadius)
	backgroundPath.addClip()

	let gradient = NSGradient(colors: [
		rgba(18, 44, 91),
		rgba(37, 98, 176),
		rgba(106, 196, 236)
	])!
	gradient.draw(in: backgroundPath, angle: -55)

	let haloRect = backgroundRect.insetBy(dx: canvas * 0.08, dy: canvas * 0.08)
	let haloGradient = NSGradient(
		colorsAndLocations:
		(rgba(255, 255, 255, 0.18), 0.0),
		(rgba(255, 255, 255, 0.0), 0.68),
		(rgba(12, 27, 58, 0.28), 1.0)
	)!
	haloGradient.draw(in: NSBezierPath(ovalIn: haloRect), relativeCenterPosition: NSPoint(x: 0, y: 0))

	let moonCenter = CGPoint(x: canvas * 0.36, y: canvas * 0.65)
	let moonRadius = canvas * 0.16
	let moonRect = CGRect(x: moonCenter.x - moonRadius, y: moonCenter.y - moonRadius, width: moonRadius * 2, height: moonRadius * 2)
	rgba(251, 247, 215).setFill()
	NSBezierPath(ovalIn: moonRect).fill()

	let cutoutRect = moonRect.offsetBy(dx: canvas * 0.07, dy: -canvas * 0.012)
	rgba(39, 99, 176).setFill()
	NSBezierPath(ovalIn: cutoutRect).fill()

	let ringRect = CGRect(x: canvas * 0.24, y: canvas * 0.19, width: canvas * 0.54, height: canvas * 0.54)
	let ringPath = NSBezierPath()
	ringPath.appendArc(withCenter: CGPoint(x: ringRect.midX, y: ringRect.midY), radius: ringRect.width / 2, startAngle: 212, endAngle: 28, clockwise: false)
	ringPath.lineWidth = canvas * 0.075
	ringPath.lineCapStyle = .round
	rgba(236, 248, 255, 0.92).setStroke()
	ringPath.stroke()

	let progressPath = NSBezierPath()
	progressPath.appendArc(withCenter: CGPoint(x: ringRect.midX, y: ringRect.midY), radius: ringRect.width / 2, startAngle: 28, endAngle: -56, clockwise: true)
	progressPath.lineWidth = canvas * 0.075
	progressPath.lineCapStyle = .round
	rgba(120, 232, 255, 0.98).setStroke()
	progressPath.stroke()

	let faceRect = ringRect.insetBy(dx: canvas * 0.085, dy: canvas * 0.085)
	rgba(13, 31, 66, 0.42).setFill()
	NSBezierPath(ovalIn: faceRect).fill()

	let center = CGPoint(x: faceRect.midX, y: faceRect.midY)
	let handPath = NSBezierPath()
	handPath.move(to: center)
	handPath.line(to: CGPoint(x: center.x + canvas * 0.11, y: center.y + canvas * 0.065))
	handPath.move(to: center)
	handPath.line(to: CGPoint(x: center.x, y: center.y + canvas * 0.135))
	handPath.lineWidth = canvas * 0.032
	handPath.lineCapStyle = .round
	rgba(255, 255, 255, 0.95).setStroke()
	handPath.stroke()

	rgba(255, 255, 255, 0.98).setFill()
	NSBezierPath(ovalIn: CGRect(x: center.x - canvas * 0.026, y: center.y - canvas * 0.026, width: canvas * 0.052, height: canvas * 0.052)).fill()

	let starColor = rgba(255, 250, 232, 0.9)
	let starRects = [
		CGRect(x: canvas * 0.68, y: canvas * 0.75, width: canvas * 0.03, height: canvas * 0.03),
		CGRect(x: canvas * 0.78, y: canvas * 0.67, width: canvas * 0.02, height: canvas * 0.02),
		CGRect(x: canvas * 0.18, y: canvas * 0.79, width: canvas * 0.018, height: canvas * 0.018)
	]
	starColor.setFill()
	for starRect in starRects {
		NSBezierPath(ovalIn: starRect).fill()
	}

	let borderPath = NSBezierPath(roundedRect: backgroundRect, xRadius: cornerRadius, yRadius: cornerRadius)
	borderPath.lineWidth = canvas * 0.012
	rgba(255, 255, 255, 0.13).setStroke()
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