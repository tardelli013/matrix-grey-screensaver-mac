import ScreenSaver
import AppKit

@objc(MatrixGreyView)
public final class MatrixGreyView: ScreenSaverView {

    private var columns: [MatrixColumn] = []
    private var lastBoundsSize: NSSize = .zero

    private var font: NSFont = .monospacedSystemFont(ofSize: 16, weight: .bold)
    private var cellWidth: CGFloat = 12
    private var cellHeight: CGFloat = 18

    private lazy var settings: Settings = {
        let id = Bundle(for: MatrixGreyView.self).bundleIdentifier ?? "com.tardelli.MatrixGrey"
        return Settings(bundleIdentifier: id)
    }()

    private lazy var configureController = ConfigureWindowController(settings: settings)

    public override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        commonInit()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func commonInit() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.cgColor
        applySettings()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(settingsDidChange),
            name: .matrixGreySettingsDidChange,
            object: nil
        )
    }

    // Flipped: y=0 is the top of the view, y grows downward.
    public override var isFlipped: Bool { true }

    private func applySettings() {
        animationTimeInterval = 1.0 / max(settings.framesPerSecond, 1)
        let basePoint = CGFloat(settings.fontPointSize)
        let pointSize: CGFloat = isPreview ? max(basePoint * 0.6, 7) : basePoint
        font = .monospacedSystemFont(ofSize: pointSize, weight: .bold)
        let metrics = ("M" as NSString).size(withAttributes: [.font: font])
        cellWidth = ceil(metrics.width)
        cellHeight = ceil(metrics.height * 1.05)
    }

    @objc private func settingsDidChange() {
        applySettings()
        lastBoundsSize = .zero
        if isAnimating {
            stopAnimation()
            startAnimation()
        }
    }

    private func rebuildColumnsIfNeeded() {
        if bounds.size == lastBoundsSize, !columns.isEmpty { return }
        lastBoundsSize = bounds.size
        let columnCount = max(1, Int(bounds.width / cellWidth))
        let rowCount = max(1, Int(bounds.height / cellHeight) + 2)
        columns = (0..<columnCount).map { i in
            MatrixColumn(x: CGFloat(i) * cellWidth, rowCount: rowCount)
        }
    }

    public override func animateOneFrame() {
        rebuildColumnsIfNeeded()
        for column in columns {
            _ = column.tick()
        }
        setNeedsDisplay(bounds)
    }

    public override func draw(_ dirtyRect: NSRect) {
        NSColor.black.setFill()
        bounds.fill()

        let head = settings.headColor
        let glow = settings.glowColor

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
                let y = CGFloat(cell.row) * cellHeight
                (cell.glyph as NSString).draw(
                    at: NSPoint(x: column.x, y: y),
                    withAttributes: attrs
                )
            }
        }
    }

    public override var hasConfigureSheet: Bool { true }
    public override var configureSheet: NSWindow? {
        configureController.window
    }
}
