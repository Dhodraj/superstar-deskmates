import Foundation
@testable import DeskmatesCore

/// The focus timer has no input, so its whole behaviour is the sequence of
/// moods it reports.
func checkFocusTimer() {
    print("FocusTimer")

    var moods: [String] = []
    let short = FocusTimer(length: 0.4)
    short.start { moods.append($0.rawValue) }
    Check.that("reports idle before any session", moods, equals: ["idle"])
    Check.that(
        "menu offers a session",
        short.menuItems().first?.title.hasPrefix("Start focus") == true,
        short.menuItems().first?.title ?? "none"
    )
    Check.that(
        "menu names the length",
        FocusTimer(length: 25 * 60).menuItems().first?.title,
        equals: Optional("Start focus (25 min)")
    )

    short.tapped()
    Check.that("starting reports busy", moods, equals: ["idle", "busy"])
    Check.that(
        "menu counts down while running",
        short.menuItems().first?.title.hasPrefix("Stop focus") == true,
        short.menuItems().first?.title ?? "none"
    )

    RunLoop.main.run(until: Date().addingTimeInterval(1.2))
    Check.that("finishing waves then rests", moods, equals: ["idle", "busy", "happy", "idle"])
    Check.that(
        "menu resets after the session",
        short.menuItems().first?.title.hasPrefix("Start focus") == true,
        short.menuItems().first?.title ?? "none"
    )

    var cancelled: [String] = []
    let long = FocusTimer(length: 600)
    long.start { cancelled.append($0.rawValue) }
    long.tapped()
    long.tapped()
    Check.that("stopping early does not wave", cancelled, equals: ["idle", "busy", "idle"])
}
