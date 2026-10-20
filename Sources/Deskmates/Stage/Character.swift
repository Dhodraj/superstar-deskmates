import AppKit

/// One character on screen: its art, its panel, and the walking it does between
/// jobs. A job attaches later and only sets the mood.
final class Character {
    let name: String
    let panel: CharacterPanel
    let view: SpriteView

    private let directory: URL
    private let scale: CGFloat
    private var wanderer: Wanderer?
    private var watcher: SheetWatcher?

    init(name: String, directory: URL, scale: CGFloat) throws {
        self.name = name
        self.directory = directory
        self.scale = scale
        let sheet = try SpriteSheet(directory: directory)
        view = SpriteView(sheet: sheet, scale: scale)
        panel = CharacterPanel(spriteView: view)
    }

    /// Brings the character out and starts everything that costs time.
    func wake(at position: NSPoint?, slot: Int) {
        if let position {
            panel.setFrameOrigin(position)
        } else {
            panel.placeOnScreen(slot: slot)
        }
        panel.orderFrontRegardless()

        let wanderer = Wanderer(panel: panel)
        self.wanderer = wanderer
        view.onDragBegan = { wanderer.pause() }
        view.onDragEnded = { wanderer.resume() }

        watcher = SheetWatcher(directory: directory) { [weak self] in self?.reloadArt() }

        view.start()
        wanderer.start()
    }

    /// Puts the character away. Nothing of it keeps running, which is what
    /// "characters sleep when hidden" has to mean to be worth saying.
    func sleep() {
        wanderer?.stop()
        wanderer = nil
        watcher = nil
        view.stop()
        panel.orderOut(nil)
    }

    var position: NSPoint {
        panel.frame.origin
    }

    private func reloadArt() {
        guard let sheet = try? SpriteSheet(directory: directory) else { return }
        view.replace(sheet: sheet)
    }
}
