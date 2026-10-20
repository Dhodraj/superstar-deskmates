import AppKit

/// Owns every character, decides who is on screen, and remembers where they
/// stood. Jobs do not touch this.
final class Stage {
    private(set) var settings = Settings.load()
    private var awake: [String: Character] = [:]
    private let pointer = PointerWatch()
    private let spritesRoot: URL
    private let scale: CGFloat

    /// Every character with art on disk, in a stable order.
    let available: [String]

    // Art is drawn at 192 pixels tall and shown at half that in points, so one
    // art pixel lands on one physical pixel of a Retina display.
    init(scale: CGFloat = 0.5) {
        self.scale = scale
        spritesRoot = Self.locateSprites()
        available = (try? FileManager.default.contentsOfDirectory(
            at: spritesRoot,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ))?
            .filter { (try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true }
            .map(\.lastPathComponent)
            .sorted() ?? []
    }

    /// Art comes from the bundle, unless `DESKMATES_SPRITES` points at the
    /// source tree. Drawing needs the second, because hot reload cannot watch a
    /// copy that only changes when the app is rebuilt.
    private static func locateSprites() -> URL {
        if let override = ProcessInfo.processInfo.environment["DESKMATES_SPRITES"] {
            return URL(fileURLWithPath: override)
        }
        return Bundle.module.resourceURL!.appendingPathComponent("sprites")
    }

    func begin() {
        var wanted = settings.active.filter(available.contains)
        if wanted.isEmpty {
            wanted = Array(available.prefix(Settings.maxOnScreen))
        }
        for name in wanted.prefix(Settings.maxOnScreen) {
            show(name)
        }
        pointer.start()
        save()
        startDebugTrace()
    }

    /// Prints where every character stands, once a second, when
    /// `DESKMATES_DEBUG` is set. The stage has no window to inspect.
    private var debugTimer: Timer?

    private func startDebugTrace() {
        guard ProcessInfo.processInfo.environment["DESKMATES_DEBUG"] != nil else { return }
        debugTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            let screen = NSScreen.main?.visibleFrame ?? .zero
            let where_ = self.awake.values
                .sorted { $0.name < $1.name }
                .map { "\($0.name) \(Int($0.panel.frame.minX)),\(Int($0.panel.frame.minY)) \(Int($0.panel.frame.width))x\(Int($0.panel.frame.height))" }
                .joined(separator: " | ")
            print("visible \(Int(screen.minX)),\(Int(screen.minY)) \(Int(screen.width))x\(Int(screen.height)) :: \(where_)")
            fflush(stdout)
        }
    }

    func end() {
        save()
        pointer.stop()
        for character in awake.values {
            character.sleep()
        }
    }

    func isAwake(_ name: String) -> Bool {
        awake[name] != nil
    }

    var isFull: Bool {
        awake.count >= Settings.maxOnScreen
    }

    func toggle(_ name: String) {
        if isAwake(name) {
            hide(name)
        } else if !isFull {
            show(name)
        }
        save()
    }

    private func show(_ name: String) {
        guard awake[name] == nil else { return }
        let directory = spritesRoot.appendingPathComponent(name)
        guard let character = try? Character(name: name, directory: directory, scale: scale) else {
            FileHandle.standardError.write("cannot load character \(name)\n".data(using: .utf8)!)
            return
        }
        character.view.contextMenu = { [weak self] in self?.menu() ?? NSMenu() }
        let saved = settings.positions[name].map { NSPoint(x: $0.x, y: $0.y) }
        character.wake(at: saved, slot: awake.count)
        pointer.watch(character.panel)
        awake[name] = character
    }

    private func hide(_ name: String) {
        guard let character = awake.removeValue(forKey: name) else { return }
        remember(character)
        character.sleep()
        pointer.forget(character.panel)
    }

    private func remember(_ character: Character) {
        settings.positions[character.name] = Settings.Position(
            x: character.position.x,
            y: character.position.y
        )
    }

    private func save() {
        for character in awake.values {
            remember(character)
        }
        settings.active = available.filter(isAwake)
        settings.save()
    }

    /// The same list in the menu bar and on a right-click, so there is one way
    /// to swap a character.
    func menu() -> NSMenu {
        let menu = NSMenu()
        fill(menu)
        return menu
    }

    /// Replaces a menu's items in place, so a long-lived menu bar menu shows
    /// the characters that are actually on screen.
    func fill(_ menu: NSMenu) {
        menu.removeAllItems()
        for name in available {
            let item = NSMenuItem(
                title: name.capitalized,
                action: #selector(MenuTarget.pick(_:)),
                keyEquivalent: ""
            )
            item.target = MenuTarget.shared
            item.representedObject = name
            item.state = isAwake(name) ? .on : .off
            item.isEnabled = isAwake(name) || !isFull
            menu.addItem(item)
        }
        menu.addItem(.separator())
        let quit = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quit.target = NSApp
        menu.addItem(quit)
    }
}

/// Menu items need an Objective-C target. One object serves every item.
final class MenuTarget: NSObject {
    static let shared = MenuTarget()
    weak var stage: Stage?

    @objc func pick(_ sender: NSMenuItem) {
        guard let name = sender.representedObject as? String else { return }
        stage?.toggle(name)
    }
}
