import AppKit

/// Spike. One character, loaded from the placeholder sheet, draggable, with a
/// right-click Quit. It exists to prove three things before any job is written:
/// a transparent panel that never steals focus, click-through on transparent
/// pixels, and frame animation that costs almost nothing.

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var panel: CharacterPanel?
    private let pointer = PointerWatch()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // SwiftPM flattens the copied folder into the bundle's Resources, so the
        // path inside the bundle starts at `sprites`, not at `Resources`.
        let directory = Bundle.module.resourceURL!
            .appendingPathComponent("sprites/placeholder")

        let sheet: SpriteSheet
        do {
            sheet = try SpriteSheet(directory: directory)
        } catch {
            FileHandle.standardError.write("cannot load \(directory.path): \(error)\n".data(using: .utf8)!)
            exit(1)
        }

        let view = SpriteView(sheet: sheet, scale: 3)
        view.onQuit = { NSApp.terminate(nil) }

        let panel = CharacterPanel(spriteView: view)
        panel.placeOnScreen()
        panel.orderFrontRegardless()
        self.panel = panel

        pointer.watch(panel)
        pointer.start()
        view.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        pointer.stop()
        panel?.spriteView.stop()
    }
}

let app = NSApplication.shared
// No Dock icon and no menu bar. The app is only its characters.
app.setActivationPolicy(.accessory)
let delegate = AppDelegate()
app.delegate = delegate
app.run()
