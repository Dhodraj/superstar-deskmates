import Foundation
@testable import DeskmatesCore

/// The focus timer reports a mood and rings on the turns. The guard is the
/// part worth checking: it must not react to a glance at another window, and
/// it must react when you stay away.
func checkFocusTimer() {
    print("FocusTimer")

    final class Stage {
        var moods: [String] = []
        var front: String? = "com.apple.dt.Xcode"
    }

    func make(length: TimeInterval, grace: TimeInterval = 0.2,
              distractions: [String] = []) -> (FocusTimer, Stage) {
        let stage = Stage()
        let timer = FocusTimer(
            length: length,
            grace: grace,
            distractions: distractions,
            frontmost: { stage.front }
        )
        timer.start { stage.moods.append($0.rawValue) }
        return (timer, stage)
    }

    func settle(_ seconds: TimeInterval) {
        RunLoop.main.run(until: Date().addingTimeInterval(seconds))
    }

    let (short, first) = make(length: 1.0)
    Check.that("reports idle before any session", first.moods, equals: ["idle"])
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
    Check.that("starting reports busy", first.moods, equals: ["idle", "busy"])
    Check.that(
        "menu counts down while running",
        short.menuItems().first?.title.hasPrefix("Stop focus") == true,
        short.menuItems().first?.title ?? "none"
    )

    settle(1.4)
    Check.that("finishing waves then rests", first.moods, equals: ["idle", "busy", "happy", "idle"])
    Check.that(
        "menu resets after the session",
        short.menuItems().first?.title.hasPrefix("Start focus") == true,
        short.menuItems().first?.title ?? "none"
    )

    let (early, second) = make(length: 600)
    early.tapped()
    early.tapped()
    Check.that("stopping early does not wave", second.moods, equals: ["idle", "busy", "idle"])
    early.stop()

    // The guard. A glance at another window is not drifting.
    let (glance, third) = make(length: 600, grace: 1.0)
    glance.tapped()
    third.front = "com.tinyspeck.slackmacgap"
    settle(0.4)
    third.front = "com.apple.dt.Xcode"
    settle(0.4)
    Check.that("a glance away is ignored", third.moods, equals: ["idle", "busy"])
    glance.stop()

    let (away, fourth) = make(length: 600, grace: 0.2)
    away.tapped()
    fourth.front = "com.tinyspeck.slackmacgap"
    settle(0.8)
    Check.that("staying away reports alert", fourth.moods, equals: ["idle", "busy", "alert"])
    Check.that(
        "the menu says you are away",
        away.menuItems().first?.title.contains("you are away") == true,
        away.menuItems().first?.title ?? "none"
    )
    fourth.front = "com.apple.dt.Xcode"
    settle(0.5)
    Check.that("coming back reports busy", fourth.moods, equals: ["idle", "busy", "alert", "busy"])
    away.stop()

    // A named list narrows what counts as drift.
    let (named, fifth) = make(length: 600, grace: 0.2, distractions: ["slack"])
    named.tapped()
    fifth.front = "com.apple.Terminal"
    settle(0.6)
    Check.that("an app not on the list is fine", fifth.moods, equals: ["idle", "busy"])
    fifth.front = "com.tinyspeck.slackmacgap"
    settle(0.6)
    Check.that("an app on the list is drift", fifth.moods.last, equals: Optional("alert"))
    named.stop()
}
