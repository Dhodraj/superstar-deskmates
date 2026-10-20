import AppKit

/// Rajni's job. Who is in the room.
///
/// He notices the apps you have open and which one is in front. Counting while
/// the desk fills up, and the coin comes out once it is crowded. This is the
/// one job copied straight from Spritefolk, where Dhiru does the same thing.
final class RunningApps: NSObject, Job {
    static let id = "running-apps"

    struct Reading: Equatable {
        var names: [String]
        var front: String?

        var count: Int { names.count }

        var summary: String {
            let word = count == 1 ? "app" : "apps"
            guard let front else { return "\(count) \(word)" }
            return "\(count) \(word), front: \(front)"
        }
    }

    /// Above this he starts counting. Above `crowdedAt` he flips the coin.
    private let busyAt: Int
    private let crowdedAt: Int
    private let interval: TimeInterval
    private let look: () -> Reading

    private var ticker: Timer?
    private var emit: ((Mood) -> Void)?
    private var mood: Mood = .idle
    private(set) var reading = Reading(names: [], front: nil)

    init(
        busyAt: Int = RunningApps.number("DESKMATES_APPS_BUSY", or: 8),
        crowdedAt: Int = RunningApps.number("DESKMATES_APPS_CROWDED", or: 14),
        interval: TimeInterval = 5,
        look: @escaping () -> Reading = RunningApps.lookAround
    ) {
        self.busyAt = busyAt
        self.crowdedAt = crowdedAt
        self.interval = interval
        self.look = look
    }

    static func number(_ name: String, or fallback: Int) -> Int {
        guard let text = ProcessInfo.processInfo.environment[name],
              let value = Int(text), value > 0
        else {
            return fallback
        }
        return value
    }

    func start(_ emit: @escaping (Mood) -> Void) {
        self.emit = emit
        emit(.idle)
        refresh()
        ticker = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.refresh()
        }
    }

    func stop() {
        ticker?.invalidate()
        ticker = nil
    }

    func tapped() {
        refresh()
    }

    func menuItems() -> [NSMenuItem] {
        let summary = NSMenuItem(title: reading.summary, action: nil, keyEquivalent: "")
        summary.isEnabled = false
        var items = [summary]
        // The list is the charm of this one. Ten is enough to be useful and
        // short enough to read.
        for name in reading.names.prefix(10) {
            let item = NSMenuItem(title: "   \(name)", action: nil, keyEquivalent: "")
            item.isEnabled = false
            items.append(item)
        }
        if reading.count > 10 {
            let more = NSMenuItem(title: "   and \(reading.count - 10) more", action: nil, keyEquivalent: "")
            more.isEnabled = false
            items.append(more)
        }
        return items
    }

    func refresh() {
        reading = look()
        let wanted = Self.mood(for: reading.count, busyAt: busyAt, crowdedAt: crowdedAt)
        guard wanted != mood else { return }
        mood = wanted
        emit?(wanted)
    }

    static func mood(for count: Int, busyAt: Int, crowdedAt: Int) -> Mood {
        if count >= crowdedAt { return .alert }
        if count >= busyAt { return .busy }
        return .idle
    }

    /// Only apps with a Dock icon. Agents and helpers are running too, and
    /// counting them would say nothing about how full the desk is.
    static func lookAround() -> Reading {
        let apps = NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular }
        let names = apps.compactMap(\.localizedName).sorted()
        let front = NSWorkspace.shared.frontmostApplication?.localizedName
        return Reading(names: names, front: front)
    }
}
