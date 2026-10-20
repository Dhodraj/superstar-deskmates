import AppKit

/// The menu bar item. The app has no Dock icon and no window, so this is the
/// only way to reach it when every character is hidden.
final class StatusItem: NSObject, NSMenuDelegate {
    private let item: NSStatusItem
    private let stage: Stage
    private let menu = NSMenu()

    init(stage: Stage) {
        self.stage = stage
        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()
        item.button?.image = NSImage(
            systemSymbolName: "figure.walk",
            accessibilityDescription: "Sprite Folk"
        )
        item.button?.image?.isTemplate = true
        menu.delegate = self
        item.menu = menu
    }

    /// Rebuilt on every open, so the checkmarks match who is on screen.
    func menuNeedsUpdate(_ menu: NSMenu) {
        stage.fill(menu)
    }
}
