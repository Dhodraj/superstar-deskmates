import AppKit

/// Rajni's job. What today's AI work has cost, read from the files Claude Code
/// and Codex already write on this Mac.
///
/// Nothing is sent anywhere. The job reads transcripts under the home folder
/// and counts.
final class TokenSpend: NSObject, Job {
    static let id = "token-spend"

    /// Today's total so far.
    struct Tally: Equatable {
        var tokens = 0
        /// Claude Code records what a session cost. Codex does not, so this is
        /// the Claude Code figure only.
        var costUSD: Double = 0
        /// A transcript was written to in the last couple of minutes.
        var working = false

        var summary: String {
            let spend = String(format: "$%.2f", costUSD)
            return "Today: \(Tally.short(tokens)) tokens, \(spend)"
        }

        static func short(_ tokens: Int) -> String {
            switch tokens {
            case 1_000_000...: return String(format: "%.1fM", Double(tokens) / 1_000_000)
            case 1_000...: return String(format: "%.0fk", Double(tokens) / 1_000)
            default: return "\(tokens)"
            }
        }
    }

    /// Where the transcripts live. One entry per tool.
    static func defaultRoots() -> [URL] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return [
            home.appendingPathComponent(".claude/projects"),
            home.appendingPathComponent(".codex/sessions"),
        ]
    }

    private let roots: [URL]
    private let alertUSD: Double
    private let interval: TimeInterval
    private let now: () -> Date
    private let play: (Chime) -> Void

    private var ticker: Timer?
    private var emit: ((Mood) -> Void)?
    private var mood: Mood = .idle
    private(set) var tally = Tally()

    init(
        roots: [URL] = TokenSpend.defaultRoots(),
        alertUSD: Double = TokenSpend.alertFromEnvironment(),
        interval: TimeInterval = 60,
        now: @escaping () -> Date = Date.init,
        play: @escaping (Chime) -> Void = Chime.ring
    ) {
        self.roots = roots
        self.alertUSD = alertUSD
        self.interval = interval
        self.now = now
        self.play = play
    }

    /// What counts as a heavy day. `DESKMATES_SPEND_ALERT` overrides it.
    static func alertFromEnvironment() -> Double {
        guard let text = ProcessInfo.processInfo.environment["DESKMATES_SPEND_ALERT"],
              let value = Double(text), value > 0
        else {
            return 20
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
        let summary = NSMenuItem(title: tally.summary, action: nil, keyEquivalent: "")
        summary.isEnabled = false
        let check = NSMenuItem(title: "Check now", action: #selector(checkNow), keyEquivalent: "")
        check.target = self
        return [summary, check]
    }

    @objc private func checkNow() {
        refresh()
    }

    func refresh() {
        tally = Self.read(roots: roots, today: now())
        let wanted: Mood = tally.costUSD >= alertUSD ? .alert : (tally.working ? .busy : .idle)
        guard wanted != mood else { return }
        // The point of the job: you hear about an expensive day while you can
        // still do something about it, not at midnight.
        if wanted == .alert {
            play(.spending)
        }
        mood = wanted
        emit?(wanted)
    }

    // MARK: reading

    /// Walks the transcripts under each root and totals today's lines.
    ///
    /// Only files touched today are opened. A transcript from last week cannot
    /// hold a line from today, and there are a lot of them.
    static func read(roots: [URL], today: Date) -> Tally {
        var tally = Tally()
        var costBySession: [String: Double] = [:]
        let manager = FileManager.default
        let recent = today.addingTimeInterval(-120)

        for root in roots {
            guard let walker = manager.enumerator(
                at: root,
                includingPropertiesForKeys: [.contentModificationDateKey],
                options: [.skipsHiddenFiles]
            ) else { continue }

            for case let file as URL in walker where file.pathExtension == "jsonl" {
                guard let changed = try? file.resourceValues(forKeys: [.contentModificationDateKey])
                    .contentModificationDate,
                      Calendar.current.isDate(changed, inSameDayAs: today)
                else { continue }
                if changed >= recent {
                    tally.working = true
                }
                guard let text = try? String(contentsOf: file, encoding: .utf8) else { continue }
                for line in text.split(separator: "\n", omittingEmptySubsequences: true) {
                    add(String(line), to: &tally, costs: &costBySession, today: today)
                }
            }
        }

        tally.costUSD = costBySession.values.reduce(0, +)
        return tally
    }

    /// Adds one transcript line. Unknown lines are ignored, which is most of
    /// them.
    static func add(
        _ line: String,
        to tally: inout Tally,
        costs: inout [String: Double],
        today: Date
    ) {
        guard let data = line.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return }

        switch object["type"] as? String {
        case "assistant":
            // Claude Code. Tokens hang off the message.
            guard sameDay(iso: object["timestamp"] as? String, as: today),
                  let message = object["message"] as? [String: Any],
                  let usage = message["usage"] as? [String: Any]
            else { return }
            // Cache reads are left out on purpose. The whole context is
            // counted again on every request, so adding them gives a number in
            // the billions that says nothing about the day's work.
            tally.tokens += tokens(in: usage, keys: [
                "input_tokens", "output_tokens", "cache_creation_input_tokens",
            ])

        case "cost-state":
            // Claude Code again, and the only place a cost appears. One line
            // per session, holding that session's running total, so keep the
            // latest per session rather than adding them up.
            guard let session = object["sessionId"] as? String,
                  let cost = object["totalCostUSD"] as? Double,
                  let started = object["startTime"] as? Double,
                  Calendar.current.isDate(
                      Date(timeIntervalSince1970: started / 1000),
                      inSameDayAs: today
                  )
            else { return }
            costs[session] = cost

        case "token_usage_record":
            // Codex. Tokens only, no cost.
            guard sameDay(iso: object["timestamp"] as? String, as: today),
                  let payload = object["payload"] as? [String: Any],
                  let usage = payload["usage"] as? [String: Any]
            else { return }
            // Codex counts cached input inside `input_tokens`, so take it
            // back out to match the Claude Code figure.
            let fresh = tokens(in: usage, keys: ["input_tokens"])
                - tokens(in: usage, keys: ["cached_input_tokens"])
            tally.tokens += max(0, fresh)
                + tokens(in: usage, keys: ["output_tokens", "cache_write_input_tokens"])

        default:
            return
        }
    }

    private static func tokens(in usage: [String: Any], keys: [String]) -> Int {
        keys.reduce(0) { total, key in total + ((usage[key] as? Int) ?? 0) }
    }

    private static let clock: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static func sameDay(iso: String?, as today: Date) -> Bool {
        guard let iso, let date = clock.date(from: iso) else { return false }
        return Calendar.current.isDate(date, inSameDayAs: today)
    }
}
