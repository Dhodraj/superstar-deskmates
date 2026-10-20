import AppKit

/// Vijay's job. A focus session, and someone watching whether you kept to it.
///
/// Click him to start. He folds his arms for the session. If you leave the app
/// you started in and stay away, he notices. He waves when the session ends.
///
/// The watching is the part a menu bar timer cannot do. Showing a countdown is
/// the part it does better, which is why the countdown is only in his menu.
final class FocusTimer: NSObject, Job {
    static let id = "focus-timer"

    /// One session. Twenty-five minutes is the usual length, and nothing here
    /// depends on the number.
    private let length: TimeInterval
    /// How long you have to stay in another app before he reacts. Switching to
    /// look something up is not drifting.
    private let grace: TimeInterval
    /// Bundle identifiers that count as drift. Empty means anything other than
    /// the app the session started in.
    private let distractions: [String]
    private let frontmost: () -> String?

    private var endsAt: Date?
    private var workApp: String?
    private var driftingSince: Date?
    private var drifted = false
    private var ticker: Timer?
    private var emit: ((Mood) -> Void)?

    init(
        length: TimeInterval = FocusTimer.lengthFromEnvironment(),
        grace: TimeInterval = 20,
        distractions: [String] = FocusTimer.distractionsFromEnvironment(),
        frontmost: @escaping () -> String? = FocusTimer.frontmostApp
    ) {
        self.length = length
        self.grace = grace
        self.distractions = distractions
        self.frontmost = frontmost
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

    /// `DESKMATES_DISTRACTIONS` is a comma separated list matched against the
    /// bundle identifier, so `slack,chrome` is enough.
    static func distractionsFromEnvironment() -> [String] {
        guard let text = ProcessInfo.processInfo.environment["DESKMATES_DISTRACTIONS"] else {
            return []
        }
        return text.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
            .filter { !$0.isEmpty }
    }

    static func frontmostApp() -> String? {
        NSWorkspace.shared.frontmostApplication?.bundleIdentifier
    }

    // MARK: job

    func start(_ emit: @escaping (Mood) -> Void) {
        self.emit = emit
        emit(.idle)
    }

    func stop() {
        ticker?.invalidate()
        ticker = nil
        endsAt = nil
        workApp = nil
        driftingSince = nil
        drifted = false
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
            let state = drifted ? ", you are away" : ""
            title = "Stop focus (\(Self.clock(until: endsAt)) left\(state))"
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

    // MARK: the session

    private func begin() {
        endsAt = Date().addingTimeInterval(length)
        workApp = frontmost()
        driftingSince = nil
        drifted = false
        emit?(.busy)
        ticker?.invalidate()
        let beat = min(1, max(0.05, min(length, grace) / 4))
        ticker = Timer.scheduledTimer(withTimeInterval: beat, repeats: true) { [weak self] _ in
            self?.beat()
        }
    }

    private func beat() {
        guard let endsAt else { return }
        if Date() >= endsAt {
            finish()
            return
        }
        watch()
    }

    /// Reacts when you have been in another app long enough to mean it.
    private func watch() {
        let now = Date()
        if away(from: frontmost()) {
            let since = driftingSince ?? now
            driftingSince = since
            if !drifted, now.timeIntervalSince(since) >= grace {
                drifted = true
                emit?(.alert)
            }
        } else {
            driftingSince = nil
            if drifted {
                drifted = false
                emit?(.busy)
            }
        }
    }

    private func away(from app: String?) -> Bool {
        guard let app, app != workApp else { return false }
        guard !distractions.isEmpty else { return true }
        return distractions.contains { app.lowercased().contains($0) }
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
