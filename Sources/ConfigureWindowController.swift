import AppKit

final class ConfigureWindowController: NSWindowController {

    private let settings: Settings

    private let headColorWell  = NSColorWell()
    private let glowColorWell  = NSColorWell()
    private let fadeSlider     = NSSlider(value: Settings.defaultFadeAlpha,
                                          minValue: 0.02, maxValue: 0.20,
                                          target: nil, action: nil)
    private let fontSlider     = NSSlider(value: Settings.defaultFontSize,
                                          minValue: 8, maxValue: 28,
                                          target: nil, action: nil)
    private let fpsSlider      = NSSlider(value: Settings.defaultFps,
                                          minValue: 15, maxValue: 60,
                                          target: nil, action: nil)
    private let fadeValueLabel = NSTextField(labelWithString: "")
    private let fontValueLabel = NSTextField(labelWithString: "")
    private let fpsValueLabel  = NSTextField(labelWithString: "")

    init(settings: Settings) {
        self.settings = settings
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 320),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Matrix Grey"
        super.init(window: window)
        buildUI()
        loadFromSettings()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not used")
    }

    private func buildUI() {
        guard let window = window else { return }

        headColorWell.target = nil
        glowColorWell.target = nil

        fontSlider.allowsTickMarkValuesOnly = true
        fontSlider.numberOfTickMarks = 21
        fpsSlider.allowsTickMarkValuesOnly = true
        fpsSlider.numberOfTickMarks = 46

        fadeSlider.target = self; fadeSlider.action = #selector(sliderChanged)
        fontSlider.target = self; fontSlider.action = #selector(sliderChanged)
        fpsSlider.target  = self; fpsSlider.action  = #selector(sliderChanged)

        fadeValueLabel.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        fontValueLabel.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        fpsValueLabel.font  = .monospacedSystemFont(ofSize: 11, weight: .regular)
        fadeValueLabel.alignment = .right
        fontValueLabel.alignment = .right
        fpsValueLabel.alignment  = .right

        for slider in [fadeSlider, fontSlider, fpsSlider] {
            slider.translatesAutoresizingMaskIntoConstraints = false
            slider.widthAnchor.constraint(greaterThanOrEqualToConstant: 220).isActive = true
        }
        for label in [fadeValueLabel, fontValueLabel, fpsValueLabel] {
            label.translatesAutoresizingMaskIntoConstraints = false
            label.widthAnchor.constraint(equalToConstant: 56).isActive = true
        }

        let grid = NSGridView(views: [
            [fieldLabel("Head color"),  headColorWell, NSGridCell.emptyContentView],
            [fieldLabel("Glow color"),  glowColorWell, NSGridCell.emptyContentView],
            [fieldLabel("Trail fade"),  fadeSlider,    fadeValueLabel],
            [fieldLabel("Font size"),   fontSlider,    fontValueLabel],
            [fieldLabel("Frame rate"),  fpsSlider,     fpsValueLabel]
        ])
        grid.rowSpacing = 12
        grid.columnSpacing = 10
        grid.column(at: 0).xPlacement = .trailing
        grid.column(at: 0).width = 100
        grid.translatesAutoresizingMaskIntoConstraints = false

        let separator = NSBox()
        separator.boxType = .separator
        separator.translatesAutoresizingMaskIntoConstraints = false

        let cancelButton = NSButton(title: "Cancel", target: self, action: #selector(cancel))
        cancelButton.bezelStyle = .rounded
        cancelButton.keyEquivalent = "\u{1b}" // Esc

        let okButton = NSButton(title: "OK", target: self, action: #selector(ok))
        okButton.bezelStyle = .rounded
        okButton.keyEquivalent = "\r" // Return

        let buttonRow = NSStackView()
        buttonRow.orientation = .horizontal
        buttonRow.spacing = 10
        buttonRow.alignment = .centerY
        buttonRow.addView(cancelButton, in: .trailing)
        buttonRow.addView(okButton, in: .trailing)
        buttonRow.translatesAutoresizingMaskIntoConstraints = false

        let content = NSView()
        content.addSubview(grid)
        content.addSubview(separator)
        content.addSubview(buttonRow)

        let inset: CGFloat = 22
        NSLayoutConstraint.activate([
            grid.topAnchor.constraint(equalTo: content.topAnchor, constant: inset),
            grid.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: inset),
            grid.trailingAnchor.constraint(lessThanOrEqualTo: content.trailingAnchor, constant: -inset),

            separator.topAnchor.constraint(equalTo: grid.bottomAnchor, constant: 18),
            separator.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: inset),
            separator.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -inset),

            buttonRow.topAnchor.constraint(equalTo: separator.bottomAnchor, constant: 14),
            buttonRow.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -inset),
            buttonRow.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -inset)
        ])

        window.contentView = content
    }

    private func fieldLabel(_ text: String) -> NSTextField {
        let label = NSTextField(labelWithString: text + ":")
        label.alignment = .right
        return label
    }

    private func loadFromSettings() {
        headColorWell.color = settings.headColor
        glowColorWell.color = settings.glowColor
        fadeSlider.doubleValue = Double(settings.fadeAlpha)
        fontSlider.doubleValue = Double(settings.fontPointSize)
        fpsSlider.doubleValue  = settings.framesPerSecond
        refreshValueLabels()
    }

    private func refreshValueLabels() {
        fadeValueLabel.stringValue = String(format: "%.2f", fadeSlider.doubleValue)
        fontValueLabel.stringValue = "\(Int(fontSlider.doubleValue)) pt"
        fpsValueLabel.stringValue  = "\(Int(fpsSlider.doubleValue)) fps"
    }

    @objc private func sliderChanged() { refreshValueLabels() }

    @objc private func ok() {
        settings.update(
            headColor: headColorWell.color,
            glowColor: glowColorWell.color,
            fadeAlpha: CGFloat(fadeSlider.doubleValue),
            fontPointSize: CGFloat(fontSlider.doubleValue),
            framesPerSecond: fpsSlider.doubleValue
        )
        NotificationCenter.default.post(name: .matrixGreySettingsDidChange, object: nil)
        dismissSheet()
    }

    @objc private func cancel() {
        dismissSheet()
    }

    private func dismissSheet() {
        guard let window = window else { return }
        if let parent = window.sheetParent {
            parent.endSheet(window)
        } else {
            // Standalone configurator window — close() fires windowWillClose
            // so the host app can terminate.
            window.close()
        }
    }
}
