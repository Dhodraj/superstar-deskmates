import AppKit

/// Vijay's job. A focus session with nothing to read: no files, no network, no
/// permissions. It is the first job for that reason.
///
/// Click him to start. He stops wandering and stands while the session runs,
/// then waves when it ends.
final class FocusTimer: NSObject, Job {
    static let id = "focus-timer"

    /// One session. Twenty-five minutes is the usual length, and nothing here
    /// depends on the number.
    private let length: TimeInterval

    init(length: TimeInterval = FocusTimer.lengthFromEnvironment()) {
        self.length = length
    }

    /// How long a session runs. `DESKMATES_FOCUS` sets it in minutes, which is
    /// how you try the thing without waiting 25 of them.
    static func lengthFromEnvironment() -> TimeInterval {
        guard let text = ProcessInfo.processInfo.environment["DESKMATES_FOCUS"],
              let minutes = Double(text), minutes > 0
        else {
            return 25 * 60
        }
        return minutes * 60
    }

    private var endsAt: Date?
    private var ticker: Timer?
    private var emit: ((Mood) -> Void)?

    func start(_ emit: @escaping (Mood) -> Void) {
        self.emit = emit
        emit(.idle)
    }

    func stop() {
        ticker?.invalidate()
        ticker = nil
        endsAt = nil
    }

    func tapped() {
        if endsAt == nil {
            begin()
        } else {
            cancel()
        }
    }

    func menuItems() -> [NSMenuItem] {
        let title: String
        if let endsAt {
            title = "Stop focus (\(Self.clock(until: endsAt)) left)"
        } else {
            title = "Start focus (\(Int((length / 60).rounded())) min)"
        }
        let item = NSMenuItem(title: title, action: #selector(toggle), keyEquivalent: "")
        item.target = self
        return [item]
    }

    @objc private func toggle() {
        tapped()
    }

    private func begin() {
        endsAt = Date().addingTimeInterval(length)
        emit?(.busy)
        ticker?.invalidate()
        // One tick a second, only to notice the end. The menu reads `endsAt`
        // directly, so nothing else depends on this firing on time.
        ticker = Timer.scheduledTimer(withTimeInterval: min(1, length / 4), repeats: true) { [weak self] _ in
            guard let self, let endsAt = self.endsAt, Date() >= endsAt else { return }
            self.finish()
        }
    }

    private func cancel() {
        stop()
        emit?(.idle)
    }

    private func finish() {
        stop()
        emit?(.happy)
        emit?(.idle)
    }

    /// Minutes and seconds, for the menu.
    private static func clock(until date: Date) -> String {
        let remaining = max(0, Int(date.timeIntervalSinceNow))
        return String(format: "%d:%02d", remaining / 60, remaining % 60)
    }
}
