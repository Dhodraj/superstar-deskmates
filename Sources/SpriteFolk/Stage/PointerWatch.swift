import AppKit

/// Makes click-through work.
///
/// AppKit has no per-pixel hit test for a window: a borderless panel either
/// takes every click inside its frame or none of them. So poll the cursor, and
/// let the panel take clicks only while the cursor is over a drawn pixel.
/// Everywhere else the panel is transparent to the mouse and the click reaches
/// the app behind it.
///
/// Polling costs one cursor read per tick. A global mouse-moved monitor would
/// be cheaper, but it reports nothing while this app is frontmost, which is
/// exactly when a character is being dragged.
final class PointerWatch {
    private let rate: TimeInterval
    private var panels: [CharacterPanel] = []
    private var timer: Timer?

    init(rate: TimeInterval = 1.0 / 20) {
        self.rate = rate
    }

    func watch(_ panel: CharacterPanel) {
        panels.append(panel)
    }

    func start() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: rate, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        let onScreen = NSEvent.mouseLocation
        for panel in panels where panel.isVisible {
            let inWindow = panel.convertPoint(fromScreen: onScreen)
            let inView = panel.spriteView.convert(inWindow, from: nil)
            panel.ignoresMouseEvents = !panel.spriteView.isOverArt(viewPoint: inView)
        }
    }
}
