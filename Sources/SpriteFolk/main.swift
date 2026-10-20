import AppKit

/// Sprite Folk. Pixel characters on the desktop, one job each.
///
/// This is the stage only: characters walk, swap and sleep. No job reads any
/// data yet.

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let stage = Stage()
    private var statusItem: StatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard !stage.available.isEmpty else {
            FileHandle.standardError.write("no characters found\n".data(using: .utf8)!)
            exit(1)
        }
        MenuTarget.shared.stage = stage
        stage.begin()
        statusItem = StatusItem(stage: stage)
    }

    func applicationWillTerminate(_ notification: Notification) {
        stage.end()
    }
}

let app = NSApplication.shared
// No Dock icon and no menu bar of its own. The app is only its characters.
app.setActivationPolicy(.accessory)
let delegate = AppDelegate()
app.delegate = delegate
app.run()
