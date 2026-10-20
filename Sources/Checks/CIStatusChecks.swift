import Foundation
@testable import DeskmatesCore

/// The CI job's behaviour is the mapping from `gh` output to a mood, plus the
/// one transition that earns a wave.
func checkCIStatus() {
    print("CIStatus")

    func run(_ status: String, _ conclusion: String, _ title: String = "Build") -> String {
        """
        [{"status":"\(status)","conclusion":"\(conclusion)","displayTitle":"\(title)"}]
        """
    }

    Check.that("a passing run is idle", CIStatus.read(run("completed", "success")).mood.rawValue, equals: "idle")
    Check.that("a failing run is alert", CIStatus.read(run("completed", "failure")).mood.rawValue, equals: "alert")
    Check.that("a cancelled run is alert", CIStatus.read(run("completed", "cancelled")).mood.rawValue, equals: "alert")
    Check.that("a running job is busy", CIStatus.read(run("in_progress", "")).mood.rawValue, equals: "busy")
    Check.that("a queued job is busy", CIStatus.read(run("queued", "")).mood.rawValue, equals: "busy")
    Check.that("no runs is unknown", CIStatus.read("[]"), equals: CIStatus.State.unknown("no runs yet"))
    Check.that("no gh is unknown", CIStatus.read(nil), equals: CIStatus.State.unknown("gh did not answer"))
    Check.that("junk is unknown", CIStatus.read("not json"), equals: CIStatus.State.unknown("could not read gh output"))
    Check.that(
        "the menu names the run",
        CIStatus.read(run("completed", "failure", "Nightly")).title,
        equals: "CI failed: Nightly"
    )

    // An unknown state must not look like a pass, or a missing `gh` would read
    // as a green build.
    Check.that("unknown is not a false green", CIStatus.read(nil) != CIStatus.read(run("completed", "success")), "distinct states")

    var answer = run("completed", "failure")
    var moods: [String] = []
    let job = CIStatus(
        repository: URL(fileURLWithPath: "/tmp"),
        interval: 3600,
        ask: { _ in answer }
    )
    job.start { moods.append($0.rawValue) }
    Check.that("a red build reports alert", moods, equals: ["idle", "alert"])

    job.refresh()
    Check.that("an unchanged state stays quiet", moods, equals: ["idle", "alert"])

    answer = run("completed", "success")
    job.refresh()
    Check.that("recovering waves then rests", moods, equals: ["idle", "alert", "happy", "idle"])

    answer = run("in_progress", "")
    job.refresh()
    Check.that("a new run reports busy", moods.last, equals: Optional("busy"))

    answer = run("completed", "success")
    job.refresh()
    Check.that("passing after a run does not wave", moods.suffix(2).joined(separator: ","), equals: "busy,idle")
    job.stop()
}
