import AppKit
import ScreenSaver

extension Notification.Name {
    static let matrixGreySettingsDidChange = Notification.Name("MatrixGreySettingsDidChange")
}

final class Settings {
    private enum Key {
        static let headColor = "headColorData"
        static let glowColor = "glowColorData"
        static let fadeAlpha = "fadeAlpha"
        static let fontSize  = "fontPointSize"
        static let fps       = "framesPerSecond"
    }

    static let defaultHeadColor = NSColor(white: 0.95, alpha: 1.0)
    static let defaultGlowColor = NSColor(white: 0.72, alpha: 1.0)
    static let defaultFadeAlpha: Double = 0.07
    static let defaultFontSize: Double  = 16
    static let defaultFps: Double       = 21

    private let defaults: UserDefaults

    init(bundleIdentifier: String) {
        self.defaults = ScreenSaverDefaults(forModuleWithName: bundleIdentifier) ?? .standard
        defaults.register(defaults: [
            Key.fadeAlpha: Settings.defaultFadeAlpha,
            Key.fontSize:  Settings.defaultFontSize,
            Key.fps:       Settings.defaultFps
        ])
    }

    var headColor: NSColor {
        Self.decodeColor(defaults.data(forKey: Key.headColor)) ?? Self.defaultHeadColor
    }

    var glowColor: NSColor {
        Self.decodeColor(defaults.data(forKey: Key.glowColor)) ?? Self.defaultGlowColor
    }

    var fadeAlpha: CGFloat { CGFloat(defaults.double(forKey: Key.fadeAlpha)) }
    var fontPointSize: CGFloat { CGFloat(defaults.double(forKey: Key.fontSize)) }
    var framesPerSecond: Double { defaults.double(forKey: Key.fps) }

    func update(headColor: NSColor,
                glowColor: NSColor,
                fadeAlpha: CGFloat,
                fontPointSize: CGFloat,
                framesPerSecond: Double) {
        if let data = Self.encodeColor(headColor) {
            defaults.set(data, forKey: Key.headColor)
        }
        if let data = Self.encodeColor(glowColor) {
            defaults.set(data, forKey: Key.glowColor)
        }
        defaults.set(Double(fadeAlpha), forKey: Key.fadeAlpha)
        defaults.set(Double(fontPointSize), forKey: Key.fontSize)
        defaults.set(framesPerSecond, forKey: Key.fps)
        defaults.synchronize()
    }

    // ScreenSaverDefaults can't store NSColor directly — archive to Data.
    private static func encodeColor(_ color: NSColor) -> Data? {
        try? NSKeyedArchiver.archivedData(withRootObject: color, requiringSecureCoding: true)
    }

    private static func decodeColor(_ data: Data?) -> NSColor? {
        guard let data = data, !data.isEmpty else { return nil }
        return try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: data)
    }
}
