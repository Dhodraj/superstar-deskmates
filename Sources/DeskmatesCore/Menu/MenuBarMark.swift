import AppKit

/// The menu bar mark: the same cutout as the app icon, in one colour.
///
/// Drawn rather than shipped as an image, for the same reason the app icon is:
/// one definition, nothing to keep in step. Marked as a template so macOS
/// tints it for a light or dark menu bar.
enum MenuBarMark {
    /// 16 by 16, where `#` is drawn and `.` is left clear. Solid, because
    /// detail inside a 16 pixel figure turns to noise.
    private static let rows = [
        "................",
        "................",
        "......####......",
        "......####......",
        "......####......",
        "......####......",
        "....########....",
        "...##########...",
        "...##########...",
        "....########....",
        ".....##..##.....",
        ".....##..##.....",
        "...##########...",
        "..############..",
        "................",
        "................",
    ]

    static func image(height: CGFloat = 18) -> NSImage {
        let scale = height / 16
        let image = NSImage(size: NSSize(width: height, height: height), flipped: true) { _ in
            NSColor.black.setFill()
            for (y, row) in rows.enumerated() {
                for (x, char) in row.enumerated() where char == "#" {
                    NSRect(
                        x: CGFloat(x) * scale,
                        y: CGFloat(y) * scale,
                        width: scale,
                        height: scale
                    ).fill()
                }
            }
            return true
        }
        image.isTemplate = true
        return image
    }
}
