import AppKit

/// Draws one character and owns its frame timer. It knows nothing about jobs.
final class SpriteView: NSView {
    private let sheet: SpriteSheet
    private var range: ClosedRange<Int>
    private var index: Int
    private var timer: Timer?
    private var dragOrigin: (mouse: NSPoint, window: NSPoint)?

    /// Called when the user picks Quit from the character's menu.
    var onQuit: (() -> Void)?

    init(sheet: SpriteSheet, scale: CGFloat) {
        self.sheet = sheet
        self.range = sheet.range(for: "idle")
        self.index = self.range.lowerBound
        super.init(frame: NSRect(origin: .zero, size: NSSize(
            width: sheet.cellSize.width * scale,
            height: sheet.cellSize.height * scale
        )))
    }

    required init?(coder: NSCoder) { fatalError("not used") }

    // MARK: animation

    func play(_ tag: String) {
        let next = sheet.range(for: tag)
        guard next != range else { return }
        range = next
        index = next.lowerBound
        needsDisplay = true
        scheduleNextFrame()
    }

    func start() {
        scheduleNextFrame()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func scheduleNextFrame() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(
            withTimeInterval: sheet.frames[index].duration,
            repeats: false
        ) { [weak self] _ in
            guard let self else { return }
            self.index = self.index >= self.range.upperBound ? self.range.lowerBound : self.index + 1
            self.needsDisplay = true
            self.scheduleNextFrame()
        }
    }

    // MARK: drawing

    override func draw(_ dirtyRect: NSRect) {
        let context = NSGraphicsContext.current
        context?.imageInterpolation = .none
        let cell = sheet.frames[index].rect
        // Aseprite measures y from the top, NSImageRep from the bottom.
        let source = NSRect(
            x: cell.minX,
            y: CGFloat(sheet.bitmap.pixelsHigh) - cell.maxY,
            width: cell.width,
            height: cell.height
        )
        sheet.bitmap.draw(
            in: bounds,
            from: source,
            operation: .sourceOver,
            fraction: 1,
            respectFlipped: true,
            hints: [.interpolation: NSImageInterpolation.none.rawValue]
        )
    }

    // MARK: hit testing

    /// True when this point in view coordinates lands on a drawn pixel.
    func isOverArt(viewPoint point: NSPoint) -> Bool {
        guard bounds.contains(point) else { return false }
        let pixel = NSPoint(
            x: point.x / bounds.width * sheet.cellSize.width,
            y: (1 - point.y / bounds.height) * sheet.cellSize.height
        )
        return sheet.isOpaque(frame: index, atPixel: pixel)
    }

    // MARK: input

    override func mouseDown(with event: NSEvent) {
        guard let window else { return }
        dragOrigin = (NSEvent.mouseLocation, window.frame.origin)
    }

    override func mouseDragged(with event: NSEvent) {
        guard let window, let origin = dragOrigin else { return }
        let now = NSEvent.mouseLocation
        window.setFrameOrigin(NSPoint(
            x: origin.window.x + now.x - origin.mouse.x,
            y: origin.window.y + now.y - origin.mouse.y
        ))
        play("walk")
    }

    override func mouseUp(with event: NSEvent) {
        dragOrigin = nil
        play("idle")
    }

    override func rightMouseDown(with event: NSEvent) {
        let menu = NSMenu()
        let quit = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "")
        quit.target = self
        menu.addItem(quit)
        NSMenu.popUpContextMenu(menu, with: event, for: self)
    }

    @objc private func quit() {
        onQuit?()
    }
}
