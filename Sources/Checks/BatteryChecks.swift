import Foundation
@testable import DeskmatesCore

/// The battery job turns a power reading into a mood and a line of text.
func checkBattery() {
    print("Battery")

    func reading(_ percent: Int, charging: Bool = false, minutes: Int? = nil) -> Battery.Reading {
        Battery.Reading(percent: percent, charging: charging, minutes: minutes)
    }
    func mood(_ r: Battery.Reading?) -> String {
        Battery.mood(for: r, lowPercent: 20).rawValue
    }

    Check.that("a full battery is idle", mood(reading(90)), equals: "idle")
    Check.that("charging is busy", mood(reading(40, charging: true)), equals: "busy")
    // Charging matters more than the level: plugged in at 5% is good news.
    Check.that("charging while low is still busy", mood(reading(5, charging: true)), equals: "busy")
    Check.that("low is alert", mood(reading(15)), equals: "alert")
    Check.that("exactly at the line is alert", mood(reading(20)), equals: "alert")
    Check.that("just above the line is idle", mood(reading(21)), equals: "idle")
    // A Mac with no battery must not look like an empty one.
    Check.that("no battery is idle", mood(nil), equals: "idle")

    Check.that("reads out the time left", reading(64, minutes: 190).summary,
               equals: "Battery 64%, 3:10 left")
    Check.that("reads out the time to full", reading(64, charging: true, minutes: 45).summary,
               equals: "Battery 64%, 0:45 to full")
    Check.that("copes with no estimate", reading(64).summary, equals: "Battery 64%")
    Check.that("copes with no estimate while charging", reading(64, charging: true).summary,
               equals: "Battery 64%, charging")

    var moods: [String] = []
    var level = reading(90)
    let job = Battery(lowPercent: 20, interval: 3600, read: { level })
    job.start { moods.append($0.rawValue) }
    Check.that("a healthy battery stays quiet", moods, equals: ["idle"])
    level = reading(10)
    job.refresh()
    Check.that("draining to low reports alert", moods, equals: ["idle", "alert"])
    job.refresh()
    Check.that("staying low says nothing more", moods, equals: ["idle", "alert"])
    level = reading(10, charging: true)
    job.refresh()
    Check.that("plugging in reports busy", moods, equals: ["idle", "alert", "busy"])
    Check.that("the menu shows the reading", job.menuItems().first?.title,
               equals: Optional("Battery 10%, charging"))
    job.stop()

    // The real reading, on whatever this machine is.
    let live = Battery.readPowerSource()
    Check.that("reads this Mac", live != nil, live.map(\.summary) ?? "no battery found")
}
