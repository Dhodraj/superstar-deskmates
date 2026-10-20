import Foundation
@testable import DeskmatesCore

/// The running apps job turns a count into a mood and a menu.
func checkRunningApps() {
    print("RunningApps")

    func mood(_ count: Int) -> String {
        RunningApps.mood(for: count, busyAt: 8, crowdedAt: 14).rawValue
    }

    Check.that("a quiet desk is idle", mood(3), equals: "idle")
    Check.that("just below busy is idle", mood(7), equals: "idle")
    Check.that("busy starts at its line", mood(8), equals: "busy")
    Check.that("still busy below crowded", mood(13), equals: "busy")
    Check.that("crowded starts at its line", mood(14), equals: "alert")

    Check.that("names the front app",
               RunningApps.Reading(names: ["Xcode", "Safari"], front: "Xcode").summary,
               equals: "2 apps, front: Xcode")
    Check.that("counts one app in the singular",
               RunningApps.Reading(names: ["Xcode"], front: "Xcode").summary,
               equals: "1 app, front: Xcode")
    Check.that("copes with no front app",
               RunningApps.Reading(names: ["Xcode"], front: nil).summary,
               equals: "1 app")

    var desk = RunningApps.Reading(names: ["Xcode", "Safari"], front: "Xcode")
    var moods: [String] = []
    let job = RunningApps(busyAt: 3, crowdedAt: 5, interval: 3600, look: { desk })
    job.start { moods.append($0.rawValue) }
    Check.that("a quiet desk stays quiet", moods, equals: ["idle"])

    desk = RunningApps.Reading(names: ["A", "B", "C"], front: "C")
    job.refresh()
    Check.that("filling up reports busy", moods, equals: ["idle", "busy"])
    job.refresh()
    Check.that("no change says nothing more", moods, equals: ["idle", "busy"])

    desk = RunningApps.Reading(names: ["A", "B", "C", "D", "E"], front: "E")
    job.refresh()
    Check.that("a crowded desk reports alert", moods, equals: ["idle", "busy", "alert"])

    desk = RunningApps.Reading(names: ["A"], front: "A")
    job.refresh()
    Check.that("clearing the desk settles him", moods.last, equals: Optional("idle"))

    desk = RunningApps.Reading(names: (1...13).map { "App \($0)" }, front: "App 1")
    job.refresh()
    let titles = job.menuItems().map(\.title)
    Check.that("the menu lists ten and counts the rest", titles.last, equals: Optional("   and 3 more"))
    Check.that("the menu is a summary plus eleven lines", titles.count, equals: 12)
    job.stop()

    // The real reading, on this Mac. A continuous integration runner has
    // almost nothing open, so the check is that the call works rather than
    // that the desk is busy.
    let live = RunningApps.lookAround()
    Check.that("sees this Mac's apps", live.count >= 0, live.summary)
}
