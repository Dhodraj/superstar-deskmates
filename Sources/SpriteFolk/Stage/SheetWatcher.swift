import Foundation

/// Reloads a character's art when its files change on disk, so drawing a frame
/// in Aseprite shows up without a rebuild.
///
/// Only useful when the app reads sprites from the source tree rather than from
/// its bundle. Set `SPRITEFOLK_SPRITES` to that directory while drawing.
final class SheetWatcher {
    private let source: DispatchSourceFileSystemObject
    private var pending: DispatchWorkItem?

    init?(directory: URL, onChange: @escaping () -> Void) {
        let descriptor = open(directory.path, O_EVTONLY)
        guard descriptor >= 0 else { return nil }

        source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: descriptor,
            eventMask: [.write, .rename, .delete, .extend],
            queue: .main
        )
        source.setCancelHandler { close(descriptor) }
        source.setEventHandler { [weak self] in
            // An export arrives as a burst of writes. Wait for it to settle,
            // otherwise the reload reads a half-written PNG.
            self?.pending?.cancel()
            let work = DispatchWorkItem(block: onChange)
            self?.pending = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: work)
        }
        source.resume()
    }

    deinit {
        pending?.cancel()
        source.cancel()
    }
}
