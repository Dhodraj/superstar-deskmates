import AppKit

/// Ajit's job. The state of the newest GitHub Actions run in one repository.
///
/// He races, so the flag is already his: green while the last run passed, the
/// helmet on while one is running, and the red flag when one failed.
final class CIStatus: NSObject, Job {
    static let id = "ci-status"

    /// What `gh` reported, reduced to what the character shows.
    enum State: Equatable {
        case passed(String)
        case failed(String)
        case running(String)
        case unknown(String)

        var mood: Mood {
            switch self {
            case .passed: return .idle
            case .failed: return .alert
            case .running: return .busy
            case .unknown: return .idle
            }
        }

        var title: String {
            switch self {
            case .passed(let run): return "CI passed: \(run)"
            case .failed(let run): return "CI failed: \(run)"
            case .running(let run): return "CI running: \(run)"
            case .unknown(let why): return "CI unknown: \(why)"
            }
        }
    }

    private let repository: URL
    private let interval: TimeInterval
    /// Returns the raw JSON `gh` printed, or nil when it could not be asked.
    private let ask: (URL) -> String?

    private var ticker: Timer?
    private var emit: ((Mood) -> Void)?
    private(set) var state: State = .unknown("not checked yet")

    init(
        repository: URL,
        interval: TimeInterval = 60,
        ask: @escaping (URL) -> String? = CIStatus.askGH
    ) {
        self.repository = repository
        self.interval = interval
        self.ask = ask
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
        let status = NSMenuItem(title: state.title, action: nil, keyEquivalent: "")
        status.isEnabled = false
        let check = NSMenuItem(title: "Check now", action: #selector(checkNow), keyEquivalent: "")
        check.target = self
        return [status, check]
    }

    @objc private func checkNow() {
        refresh()
    }

    /// Reads the newest run and reports the mood it maps to.
    func refresh() {
        let previous = state
        state = Self.read(ask(repository))
        guard state != previous else { return }
        // A run that goes from red to green is worth a wave. Staying green is
        // not, or the character would celebrate every poll.
        if case .failed = previous, case .passed = state {
            emit?(.happy)
        }
        emit?(state.mood)
    }

    /// Turns `gh`'s JSON into a state. Anything unexpected is `unknown`, which
    /// shows as an ordinary idle character rather than a false green.
    static func read(_ json: String?) -> State {
        struct Run: Decodable {
            let status: String
            let conclusion: String
            let displayTitle: String
        }
        guard let json, let data = json.data(using: .utf8) else {
            return .unknown("gh did not answer")
        }
        guard let runs = try? JSONDecoder().decode([Run].self, from: data) else {
            return .unknown("could not read gh output")
        }
        guard let run = runs.first else {
            return .unknown("no runs yet")
        }
        if run.status != "completed" {
            return .running(run.displayTitle)
        }
        return run.conclusion == "success" ? .passed(run.displayTitle) : .failed(run.displayTitle)
    }

    /// The one place that shells out.
    static func askGH(in repository: URL) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = [
            "gh", "run", "list",
            "--limit", "1",
            "--json", "status,conclusion,displayTitle",
        ]
        process.currentDirectoryURL = repository
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        guard (try? process.run()) != nil else { return nil }
        let output = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else { return nil }
        return String(data: output, encoding: .utf8)
    }
}
