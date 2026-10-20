import Foundation
@testable import DeskmatesCore

/// The token job is a reader, so its behaviour is which lines it counts and
/// which it ignores. The checks write real transcript files and read them.
func checkTokenSpend() {
    print("TokenSpend")

    let today = Date()
    let iso = ISO8601DateFormatter()
    iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    let stamp = iso.string(from: today)
    let yesterday = iso.string(from: today.addingTimeInterval(-60 * 60 * 24))

    func claudeAssistant(_ when: String, input: Int, output: Int, cache: Int,
                         cacheRead: Int = 0) -> String {
        """
        {"type":"assistant","timestamp":"\(when)","message":{"model":"claude-opus-5",\
        "usage":{"input_tokens":\(input),"output_tokens":\(output),\
        "cache_creation_input_tokens":\(cache),"cache_read_input_tokens":\(cacheRead)}}}
        """
    }
    func costState(_ session: String, _ cost: Double, startedToday: Bool) -> String {
        let start = (startedToday ? today : today.addingTimeInterval(-60 * 60 * 48))
            .timeIntervalSince1970 * 1000
        return """
        {"type":"cost-state","sessionId":"\(session)","totalCostUSD":\(cost),"startTime":\(start)}
        """
    }
    func codexRecord(_ when: String, input: Int, output: Int, cached: Int = 0) -> String {
        """
        {"type":"token_usage_record","timestamp":"\(when)","payload":{"usage":\
        {"input_tokens":\(input),"cached_input_tokens":\(cached),"output_tokens":\(output),\
        "cache_write_input_tokens":0}}}
        """
    }

    // Line-level counting, with no files involved.
    func tally(_ lines: [String]) -> TokenSpend.Tally {
        var result = TokenSpend.Tally()
        var costs: [String: Double] = [:]
        for line in lines {
            TokenSpend.add(line, to: &result, costs: &costs, today: today)
        }
        result.costUSD = costs.values.reduce(0, +)
        return result
    }

    Check.that("counts every token field",
               tally([claudeAssistant(stamp, input: 10, output: 20, cache: 5)]).tokens, equals: 35)
    Check.that("ignores yesterday's lines",
               tally([claudeAssistant(yesterday, input: 10, output: 20, cache: 5)]).tokens, equals: 0)
    Check.that("counts Codex records",
               tally([codexRecord(stamp, input: 7, output: 3)]).tokens, equals: 10)
    // Cache reads would otherwise dominate: the whole context is counted again
    // on every request, which put a real day at 1.4 billion tokens.
    Check.that("leaves out Claude cache reads",
               tally([claudeAssistant(stamp, input: 10, output: 20, cache: 5,
                                      cacheRead: 900_000)]).tokens, equals: 35)
    Check.that("takes Codex cached input back out",
               tally([codexRecord(stamp, input: 1000, output: 50, cached: 900)]).tokens,
               equals: 150)
    Check.that("ignores lines it does not know",
               tally(["{\"type\":\"queue-operation\"}", "not json"]).tokens, equals: 0)
    Check.that("adds cost from cost-state",
               tally([costState("a", 1.25, startedToday: true)]).costUSD, equals: 1.25)
    Check.that("ignores a session that started another day",
               tally([costState("a", 1.25, startedToday: false)]).costUSD, equals: 0.0)
    // A session's cost line holds a running total, so two of them must not add.
    Check.that("keeps the latest cost per session, not the sum",
               tally([costState("a", 1.0, startedToday: true),
                      costState("a", 2.5, startedToday: true)]).costUSD, equals: 2.5)
    Check.that("adds cost across sessions",
               tally([costState("a", 1.0, startedToday: true),
                      costState("b", 0.5, startedToday: true)]).costUSD, equals: 1.5)
    // printf rounds 1.25 down to even, so this is 1.2M rather than 1.3M.
    Check.that("formats a large count", TokenSpend.Tally.short(1_250_000), equals: "1.2M")
    Check.that("rounds a large count up", TokenSpend.Tally.short(1_260_000), equals: "1.3M")
    Check.that("formats a medium count", TokenSpend.Tally.short(45_300), equals: "45k")

    // Now through real files, which is where the date filter and the walk live.
    let root = URL(fileURLWithPath: NSTemporaryDirectory())
        .appendingPathComponent("deskmates-checks-\(UUID().uuidString)")
    let nested = root.appendingPathComponent("a-project")
    try? FileManager.default.createDirectory(at: nested, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: root) }

    let session = nested.appendingPathComponent("session.jsonl")
    try? [
        claudeAssistant(stamp, input: 100, output: 200, cache: 0),
        claudeAssistant(yesterday, input: 999, output: 999, cache: 0),
        costState("s1", 3.5, startedToday: true),
    ].joined(separator: "\n").write(to: session, atomically: true, encoding: .utf8)

    let stale = nested.appendingPathComponent("ignored.txt")
    try? claudeAssistant(stamp, input: 500, output: 500, cache: 0)
        .write(to: stale, atomically: true, encoding: .utf8)

    let read = TokenSpend.read(roots: [root], today: today)
    Check.that("reads nested transcripts", read.tokens, equals: 300)
    Check.that("reads the cost", read.costUSD, equals: 3.5)
    Check.that("ignores files that are not jsonl", read.tokens, equals: 300)
    Check.that("notices recent work", read.working, "working=\(read.working)")
    Check.that("summarises for the menu", read.summary, equals: "Today: 300 tokens, $3.50")

    var moods: [String] = []
    var chimes: [String] = []
    let job = TokenSpend(roots: [root], alertUSD: 1, interval: 3600, now: { today },
                         play: { chimes.append("\($0)") })
    job.start { moods.append($0.rawValue) }
    Check.that("a heavy day reports alert", moods, equals: ["idle", "alert"])
    Check.that("crossing the line rings", chimes, equals: ["spending"])
    job.refresh()
    Check.that("an unchanged day stays quiet", moods, equals: ["idle", "alert"])
    Check.that("an unchanged day is silent", chimes, equals: ["spending"])
    job.stop()

    var quiet: [String] = []
    var silence: [String] = []
    let calm = TokenSpend(roots: [root], alertUSD: 1000, interval: 3600, now: { today },
                          play: { silence.append("\($0)") })
    calm.start { quiet.append($0.rawValue) }
    Check.that("a working day reports busy", quiet.last, equals: Optional("busy"))
    Check.that("a quiet day is silent", silence, equals: [String]())
    calm.stop()
}
