import AppKit

/// Superstar Deskmates. Pixel characters on the desktop, one job each.
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
        watchSignals()
    }

    func applicationWillTerminate(_ notification: Notification) {
        stage.end()
    }

    /// Held so the sources stay alive for the life of the app.
    private var signals: [DispatchSourceSignal] = []

    func watchSignals() {
        signals = [SIGTERM, SIGINT].map { number in
            saveOnSignal(number) { [weak self] in self?.stage.end() }
        }
    }
}

/// macOS does not route SIGTERM through `applicationWillTerminate`, so a
/// character's position was lost whenever the app was stopped from a terminal
/// rather than from its own menu.
private func saveOnSignal(_ number: Int32, _ save: @escaping () -> Void) -> DispatchSourceSignal {
    signal(number, SIG_IGN)
    let source = DispatchSource.makeSignalSource(signal: number, queue: .main)
    source.setEventHandler {
        save()
        exit(0)
    }
    source.resume()
    return source
}

/// Starts the app. The executable target is this call and nothing else, so
/// everything here can be reached from a test.
public func run() -> Never {
    let app = NSApplication.shared
    // No Dock icon and no menu bar of its own. The app is only its characters.
    app.setActivationPolicy(.accessory)
    let delegate = AppDelegate()
    app.delegate = delegate
    // The delegate outlives this scope only because NSApplication holds it.
    app.run()
    exit(0)
}
