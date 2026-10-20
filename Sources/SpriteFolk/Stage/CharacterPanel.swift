import AppKit

/// A borderless, non-activating panel that holds one character. It sits above
/// normal windows, follows the user across Spaces, and never takes focus.
final class CharacterPanel: NSPanel {
    let spriteView: SpriteView

    init(spriteView: SpriteView) {
        self.spriteView = spriteView
        super.init(
            contentRect: spriteView.bounds,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        level = .statusBar
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        isFloatingPanel = true
        becomesKeyOnlyIfNeeded = true
        hidesOnDeactivate = false
        isMovableByWindowBackground = false
        // macOS restores window frames on launch, which lands after wake() has
        // set the saved position and silently overrides it.
        isRestorable = false
        // Starts transparent to the mouse. PointerWatch turns this off while the
        // cursor is over a drawn pixel, which is what makes click-through work.
        ignoresMouseEvents = true
        contentView = spriteView
    }

    override var canBecomeKey: Bool { true }

    /// Puts the character near the bottom right of the screen it starts on.
    /// `slot` spreads the first few characters out instead of stacking them.
    func placeOnScreen(slot: Int) {
        guard let visible = (screen ?? NSScreen.main)?.visibleFrame else { return }
        setFrameOrigin(NSPoint(
            x: visible.maxX - frame.width - 80 - CGFloat(slot) * (frame.width + 40),
            y: visible.minY + 80
        ))
    }
}
