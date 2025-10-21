#!/usr/bin/env swift
import Foundation
import CoreGraphics
import ImageIO

struct IconSpec {
    let idiom: String
    let sizePoint: String
    let scale: String
    let filename: String
    let pixelSize: Int
}

let iconSpecs: [IconSpec] = [
    // iPhone
    .init(idiom: "iphone", sizePoint: "20x20", scale: "2x", filename: "icon-20@2x.png", pixelSize: 40),
    .init(idiom: "iphone", sizePoint: "20x20", scale: "3x", filename: "icon-20@3x.png", pixelSize: 60),
    .init(idiom: "iphone", sizePoint: "29x29", scale: "2x", filename: "icon-29@2x.png", pixelSize: 58),
    .init(idiom: "iphone", sizePoint: "29x29", scale: "3x", filename: "icon-29@3x.png", pixelSize: 87),
    .init(idiom: "iphone", sizePoint: "40x40", scale: "2x", filename: "icon-40@2x.png", pixelSize: 80),
    .init(idiom: "iphone", sizePoint: "40x40", scale: "3x", filename: "icon-40@3x.png", pixelSize: 120),
    .init(idiom: "iphone", sizePoint: "60x60", scale: "2x", filename: "icon-60@2x.png", pixelSize: 120),
    .init(idiom: "iphone", sizePoint: "60x60", scale: "3x", filename: "icon-60@3x.png", pixelSize: 180),
    // iPad
    .init(idiom: "ipad", sizePoint: "20x20", scale: "1x", filename: "icon-20-ipad.png", pixelSize: 20),
    .init(idiom: "ipad", sizePoint: "20x20", scale: "2x", filename: "icon-20-ipad@2x.png", pixelSize: 40),
    .init(idiom: "ipad", sizePoint: "29x29", scale: "1x", filename: "icon-29-ipad.png", pixelSize: 29),
    .init(idiom: "ipad", sizePoint: "29x29", scale: "2x", filename: "icon-29-ipad@2x.png", pixelSize: 58),
    .init(idiom: "ipad", sizePoint: "40x40", scale: "1x", filename: "icon-40-ipad.png", pixelSize: 40),
    .init(idiom: "ipad", sizePoint: "40x40", scale: "2x", filename: "icon-40-ipad@2x.png", pixelSize: 80),
    .init(idiom: "ipad", sizePoint: "76x76", scale: "1x", filename: "icon-76.png", pixelSize: 76),
    .init(idiom: "ipad", sizePoint: "76x76", scale: "2x", filename: "icon-76@2x.png", pixelSize: 152),
    .init(idiom: "ipad", sizePoint: "83.5x83.5", scale: "2x", filename: "icon-83.5@2x.png", pixelSize: 167),
    // Marketing
    .init(idiom: "ios-marketing", sizePoint: "1024x1024", scale: "1x", filename: "icon-1024.png", pixelSize: 1024)
]

func ensureDir(_ path: String) throws {
    try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)
}

func writePNG(context: CGContext, to url: URL) {
    guard let image = context.makeImage(),
          let dest = CGImageDestinationCreateWithURL(url as CFURL, kUTTypePNG, 1, nil) else { return }
    CGImageDestinationAddImage(dest, image, nil)
    CGImageDestinationFinalize(dest)
}

func drawIcon(size: Int) -> CGContext? {
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    guard let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: size * 4, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
        return nil
    }
    ctx.interpolationQuality = .high
    let rect = CGRect(x: 0, y: 0, width: size, height: size)

    // Background gradient (blue shades)
    let colors = [
        CGColor(red: 0.06, green: 0.40, blue: 0.95, alpha: 1.0), // top blue
        CGColor(red: 0.16, green: 0.55, blue: 0.99, alpha: 1.0)  // bottom blue
    ] as CFArray
    let locations: [CGFloat] = [0.0, 1.0]
    if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: locations) {
        ctx.drawLinearGradient(gradient, start: CGPoint(x: size/2, y: 0), end: CGPoint(x: size/2, y: size), options: [])
    } else {
        ctx.setFillColor(CGColor(red: 0.10, green: 0.50, blue: 1.0, alpha: 1.0))
        ctx.fill(rect)
    }

    // Draw a centered 5-point star
    let center = CGPoint(x: rect.midX, y: rect.midY)
    let outerRadius = CGFloat(size) * 0.36
    let innerRadius = outerRadius * 0.5
    let points = 5
    let path = CGMutablePath()
    let angleIncrement = .pi * 2.0 / CGFloat(points)
    let startAngle = -CGFloat.pi / 2.0
    for i in 0..<(points * 2) {
        let angle = startAngle + CGFloat(i) * (angleIncrement / 2)
        let r = (i % 2 == 0) ? outerRadius : innerRadius
        let x = center.x + r * cos(angle)
        let y = center.y + r * sin(angle)
        if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
        else { path.addLine(to: CGPoint(x: x, y: y)) }
    }
    path.closeSubpath()

    // Soft shadow
    ctx.setShadow(offset: CGSize(width: 0, height: size >= 120 ? 6 : 2), blur: size >= 120 ? 12 : 4, color: CGColor(gray: 0, alpha: 0.25))
    ctx.setFillColor(CGColor.white)
    ctx.addPath(path)
    ctx.fillPath()

    return ctx
}

func writeContentsJSON(at url: URL, specs: [IconSpec]) throws {
    var images: [[String: Any]] = []
    for s in specs {
        var entry: [String: Any] = [
            "idiom": s.idiom,
            "size": s.sizePoint,
            "scale": s.scale,
            "filename": s.filename
        ]
        images.append(entry)
    }
    let obj: [String: Any] = [
        "images": images,
        "info": ["version": 1, "author": "xcode"]
    ]
    let data = try JSONSerialization.data(withJSONObject: obj, options: [.prettyPrinted])
    try data.write(to: url)
}

let appIconDir = "NotesApp/Assets.xcassets/AppIcon.appiconset"
do {
    try ensureDir(appIconDir)
    // Generate icons
    for spec in iconSpecs {
        if let ctx = drawIcon(size: spec.pixelSize) {
            let outURL = URL(fileURLWithPath: appIconDir).appendingPathComponent(spec.filename)
            writePNG(context: ctx, to: outURL)
        }
    }
    try writeContentsJSON(at: URL(fileURLWithPath: appIconDir).appendingPathComponent("Contents.json"), specs: iconSpecs)
    FileHandle.standardOutput.write("Generated AppIcon set with blue-white star icons.\n".data(using: .utf8)!)
} catch {
    FileHandle.standardError.write("Failed to generate app icons: \(error)\n".data(using: .utf8)!)
    exit(1)
}

