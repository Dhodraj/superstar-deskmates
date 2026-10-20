import AppKit

/// Draws one character and owns its frame timer. It knows nothing about jobs.
final class SpriteView: NSView {
    private var sheet: SpriteSheet
    private let scale: CGFloat
    /// Name of the animation playing now. `tag` is taken by NSView.
    private var animation = "idle"
    private var range: ClosedRange<Int>
    private var index: Int
    private var timer: Timer?
    private var dragOrigin: (mouse: NSPoint, window: NSPoint)?

    /// Set while walking left, so the sprite faces the way it is going.
    var facingLeft = false {
        didSet { if facingLeft != oldValue { needsDisplay = true } }
    }

    /// Supplied by the stage, which owns the list of characters.
    var contextMenu: (() -> NSMenu)?
    var onDragBegan: (() -> Void)?
    var onDragEnded: (() -> Void)?

    init(sheet: SpriteSheet, scale: CGFloat) {
        self.sheet = sheet
        self.scale = scale
        self.range = sheet.range(for: "idle")
        self.index = self.range.lowerBound
        super.init(frame: NSRect(origin: .zero, size: Self.size(of: sheet, scale: scale)))
    }

    required init?(coder: NSCoder) { fatalError("not used") }

    static func size(of sheet: SpriteSheet, scale: CGFloat) -> NSSize {
        NSSize(width: sheet.cellSize.width * scale, height: sheet.cellSize.height * scale)
    }

    // MARK: animation

    func play(_ wanted: String) {
        guard wanted != animation else { return }
        animation = wanted
        range = sheet.range(for: wanted)
        index = range.lowerBound
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

    /// Swaps in freshly exported art and keeps playing whatever was playing.
    func replace(sheet newSheet: SpriteSheet) {
        sheet = newSheet
        range = newSheet.range(for: animation)
        index = range.lowerBound
        setFrameSize(Self.size(of: newSheet, scale: scale))
        window?.setContentSize(frame.size)
        needsDisplay = true
        if timer != nil { scheduleNextFrame() }
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
        guard let context = NSGraphicsContext.current else { return }
        context.imageInterpolation = .none
        context.saveGraphicsState()
        if facingLeft {
            let flip = NSAffineTransform()
            flip.translateX(by: bounds.width, yBy: 0)
            flip.scaleX(by: -1, yBy: 1)
            flip.concat()
        }
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
        context.restoreGraphicsState()
    }

    // MARK: hit testing

    /// True when this point in view coordinates lands on a drawn pixel.
    func isOverArt(viewPoint point: NSPoint) -> Bool {
        guard bounds.contains(point) else { return false }
        let x = facingLeft ? bounds.width - point.x : point.x
        let pixel = NSPoint(
            x: x / bounds.width * sheet.cellSize.width,
            y: (1 - point.y / bounds.height) * sheet.cellSize.height
        )
        return sheet.isOpaque(frame: index, atPixel: pixel)
    }

    // MARK: input

    override func mouseDown(with event: NSEvent) {
        guard let window else { return }
        dragOrigin = (NSEvent.mouseLocation, window.frame.origin)
        onDragBegan?()
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
        onDragEnded?()
    }

    override func rightMouseDown(with event: NSEvent) {
        guard let menu = contextMenu?() else { return }
        NSMenu.popUpContextMenu(menu, with: event, for: self)
    }
}
