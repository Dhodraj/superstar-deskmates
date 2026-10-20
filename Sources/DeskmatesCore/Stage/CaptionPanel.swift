import AppKit

/// A small line of text that floats above a character.
///
/// Separate from the character's own panel on purpose. The sprite panel is
/// exactly one cell of the sheet, and the alpha hit test maps the cursor
/// through those bounds, so growing it to make room for text would break
/// click-through.
final class CaptionPanel: NSPanel {
    private let label = CaptionView()

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 10, height: CaptionView.height),
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
        isRestorable = false
        // Never takes a click. It is a readout, not a control.
        ignoresMouseEvents = true
        contentView = label
    }

    /// Puts the text centred above `frame`, or hides it when there is none.
    func show(_ text: String?, above frame: NSRect) {
        guard let text, !text.isEmpty else {
            orderOut(nil)
            return
        }
        label.text = text
        let size = NSSize(width: label.width, height: CaptionView.height)
        setFrame(
            NSRect(
                x: frame.midX - size.width / 2,
                y: frame.maxY + 2,
                width: size.width,
                height: size.height
            ),
            display: true
        )
        orderFrontRegardless()
    }
}

/// Draws the text in a dark rounded pill, so it stays readable on any desktop.
private final class CaptionView: NSView {
    static let height: CGFloat = 20
    private static let padding: CGFloat = 8

    var text = "" {
        didSet {
            if text != oldValue { needsDisplay = true }
        }
    }

    private var attributes: [NSAttributedString.Key: Any] {
        [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .semibold),
            .foregroundColor: NSColor.white,
        ]
    }

    var width: CGFloat {
        (text as NSString).size(withAttributes: attributes).width + Self.padding * 2
    }

    override func draw(_ dirtyRect: NSRect) {
        let pill = NSBezierPath(roundedRect: bounds, xRadius: bounds.height / 2, yRadius: bounds.height / 2)
        NSColor.black.withAlphaComponent(0.78).setFill()
        pill.fill()

        let size = (text as NSString).size(withAttributes: attributes)
        (text as NSString).draw(
            at: NSPoint(x: (bounds.width - size.width) / 2, y: (bounds.height - size.height) / 2),
            withAttributes: attributes
        )
    }
}
