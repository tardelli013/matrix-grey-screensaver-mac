import AppKit

// Tiny standalone renderer that reuses Sources/Glyphs.swift and
// Sources/MatrixColumn.swift to produce a static PNG snapshot of the
// screensaver's look — used as the README preview image.

guard CommandLine.arguments.count >= 2 else {
    FileHandle.standardError.write(
        Data("usage: RenderPreview <output.png> [width] [height]\n".utf8)
    )
    exit(64)
}

let outputPath = CommandLine.arguments[1]
let width = CommandLine.arguments.count >= 3 ? (Int(CommandLine.arguments[2]) ?? 1280) : 1280
let height = CommandLine.arguments.count >= 4 ? (Int(CommandLine.arguments[3]) ?? 720) : 720

let font = NSFont.monospacedSystemFont(ofSize: 16, weight: .bold)
let metrics = ("M" as NSString).size(withAttributes: [.font: font])
let cellWidth = ceil(metrics.width)
let cellHeight = ceil(metrics.height * 1.05)

let columnCount = max(1, Int(CGFloat(width) / cellWidth))
let rowCount = max(1, Int(CGFloat(height) / cellHeight) + 2)

let columns = (0..<columnCount).map { i in
    MatrixColumn(x: CGFloat(i) * cellWidth, rowCount: rowCount)
}

// Warm up: simulate enough frames so columns develop full trails at varied positions.
for _ in 0..<240 {
    for column in columns { _ = column.tick() }
}

guard let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: width, pixelsHigh: height,
    bitsPerSample: 8, samplesPerPixel: 4,
    hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0, bitsPerPixel: 0
) else {
    FileHandle.standardError.write(Data("failed to allocate bitmap\n".utf8))
    exit(1)
}

NSGraphicsContext.saveGraphicsState()
guard let ctx = NSGraphicsContext(bitmapImageRep: bitmap) else {
    FileHandle.standardError.write(Data("failed to create graphics context\n".utf8))
    exit(1)
}
NSGraphicsContext.current = ctx

NSColor.black.setFill()
NSRect(x: 0, y: 0, width: width, height: height).fill()

// Y-up bitmap context: the lower-left of NSString.draw(at:) is the y given.
// Place row 0 at the visual top of the image.
let topY = CGFloat(height) - cellHeight

let head = NSColor(white: 0.95, alpha: 1.0)
let glow = NSColor(white: 0.72, alpha: 1.0)

for column in columns {
    for cell in column.cells {
        guard cell.row >= 0, cell.row < column.rowCount else { continue }
        let distance = column.row - cell.row

        let color: NSColor
        if distance == 0 {
            color = head
        } else if distance == 1 {
            color = glow
        } else {
            let span = max(column.trailLength - 1, 1)
            let t = min(Double(distance - 1) / Double(span), 1.0)
            let brightness = max(0.05, 0.55 * (1.0 - t))
            color = NSColor(white: CGFloat(brightness), alpha: 1.0)
        }

        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color
        ]
        let y = topY - CGFloat(cell.row) * cellHeight
        (cell.glyph as NSString).draw(
            at: NSPoint(x: column.x, y: y),
            withAttributes: attrs
        )
    }
}

NSGraphicsContext.restoreGraphicsState()

guard let png = bitmap.representation(using: .png, properties: [:]) else {
    FileHandle.standardError.write(Data("failed to encode PNG\n".utf8))
    exit(2)
}

do {
    try png.write(to: URL(fileURLWithPath: outputPath))
    print("Wrote \(outputPath) (\(width)×\(height))")
} catch {
    FileHandle.standardError.write(Data("write failed: \(error)\n".utf8))
    exit(3)
}
