import AppKit

/// How a character feels. A job reports one of these; the sprite sheet decides
/// what it looks like. This is the only contract between a job and the art, so
/// either side can be replaced without touching the other.
enum Mood: String {
    case idle
    case busy
    case alert
    case happy
    case sleep
}

/// One character's work. A job reads something and reports a mood. It never
/// names a frame, moves a window, or knows which character it belongs to.
protocol Job: AnyObject {
    static var id: String { get }

    /// Called once when the character wakes. Keep `emit` and call it whenever
    /// the mood changes.
    func start(_ emit: @escaping (Mood) -> Void)
    func stop()

    /// The character was clicked.
    func tapped()

    /// Extra entries for the character's right-click menu.
    func menuItems() -> [NSMenuItem]
}

extension Job {
    func tapped() {}
    func menuItems() -> [NSMenuItem] { [] }
}
