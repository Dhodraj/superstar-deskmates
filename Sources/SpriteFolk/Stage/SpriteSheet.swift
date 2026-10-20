import AppKit

/// The subset of Aseprite's `--format json-array --list-tags` export that the
/// stage needs. Field names match the file, so nothing is renamed on the way in.
private struct AsepriteExport: Decodable {
    struct Rect: Decodable {
        let x: Int
        let y: Int
        let w: Int
        let h: Int
    }

    struct Frame: Decodable {
        let frame: Rect
        /// Milliseconds, as Aseprite writes it.
        let duration: Int
    }

    struct Tag: Decodable {
        let name: String
        let from: Int
        let to: Int
    }

    struct Meta: Decodable {
        let frameTags: [Tag]
    }

    let frames: [Frame]
    let meta: Meta
}

/// One character's art: the sheet bitmap, the frame rectangles, and the tag
/// ranges that name them.
final class SpriteSheet {
    struct Frame {
        /// Pixel rectangle inside the sheet, with y measured from the top.
        let rect: NSRect
        let duration: TimeInterval
    }

    let bitmap: NSBitmapImageRep
    let frames: [Frame]
    let cellSize: NSSize
    private let tags: [String: ClosedRange<Int>]

    init(directory: URL) throws {
        let json = try Data(contentsOf: directory.appendingPathComponent("sheet.json"))
        let export = try JSONDecoder().decode(AsepriteExport.self, from: json)

        let pngURL = directory.appendingPathComponent("sheet.png")
        guard let image = NSImage(contentsOf: pngURL),
              let rep = image.representations.compactMap({ $0 as? NSBitmapImageRep }).first
        else {
            throw SheetError.unreadablePNG(pngURL)
        }
        guard let first = export.frames.first else {
            throw SheetError.noFrames(pngURL)
        }

        bitmap = rep
        cellSize = NSSize(width: first.frame.w, height: first.frame.h)
        frames = export.frames.map {
            Frame(
                rect: NSRect(x: $0.frame.x, y: $0.frame.y, width: $0.frame.w, height: $0.frame.h),
                duration: TimeInterval($0.duration) / 1000
            )
        }
        tags = Dictionary(
            export.meta.frameTags.map { ($0.name, $0.from...$0.to) },
            uniquingKeysWith: { first, _ in first }
        )
    }

    /// Frame range for a tag. A missing tag falls back to `idle`, then to the
    /// whole sheet, so art with one animation still runs.
    func range(for tag: String) -> ClosedRange<Int> {
        tags[tag] ?? tags["idle"] ?? 0...(frames.count - 1)
    }

    /// True when the pixel at this point inside a drawn cell is not transparent.
    /// `point` is in cell pixels with y measured from the top.
    func isOpaque(frame index: Int, atPixel point: NSPoint) -> Bool {
        let rect = frames[index].rect
        let x = Int(rect.minX + point.x)
        let y = Int(rect.minY + point.y)
        guard x >= 0, y >= 0, x < bitmap.pixelsWide, y < bitmap.pixelsHigh else { return false }
        return (bitmap.colorAt(x: x, y: y)?.alphaComponent ?? 0) > 0.1
    }

    enum SheetError: Error {
        case unreadablePNG(URL)
        case noFrames(URL)
    }
}
