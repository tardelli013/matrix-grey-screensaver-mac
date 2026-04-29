import AppKit

final class ConfiguratorAppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private var controller: ConfigureWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let settings = Settings(bundleIdentifier: "com.tardelli.MatrixGrey")
        let controller = ConfigureWindowController(settings: settings)
        self.controller = controller

        if let window = controller.window {
            window.delegate = self
            window.center()
        }
        controller.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func windowWillClose(_ notification: Notification) {
        NSApp.terminate(nil)
    }
}

let app = NSApplication.shared
let delegate = ConfiguratorAppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()
