import AppKit
@testable import DeskmatesCore

/// The menus are assembled in two places from one list, and a right-click menu
/// also carries that character's job entries. Those entries went missing once,
/// because filling the list cleared the menu first.
func checkMenus() {
    print("Menus")

    let stage = Stage()
    Check.that("finds the characters on disk", stage.available, equals: ["ajit", "rajni", "vijay"])

    let plain = stage.menu()
    let titles = plain.items.map(\.title)
    Check.that("lists every character", titles.prefix(3).map { $0 }, equals: ["Ajit", "Rajni", "Vijay"])
    Check.that("offers Quit last", titles.last, equals: Optional("Quit"))

    // Filling must add to a menu, not replace what is in it.
    let withJob = NSMenu()
    withJob.addItem(NSMenuItem(title: "Start focus (25 min)", action: nil, keyEquivalent: ""))
    withJob.addItem(.separator())
    stage.fill(withJob)
    Check.that("filling keeps what was already there",
               withJob.items.first?.title, equals: Optional("Start focus (25 min)"))
    Check.that("filling adds the characters below",
               withJob.items.map(\.title).contains("Vijay"), "\(withJob.items.count) items")
}
