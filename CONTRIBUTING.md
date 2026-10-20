# Contributing

Two kinds of change are easy here, by design. Pick one and the rest of the
app stays out of your way.

Before anything else:

```
swift build && swift run Checks
```

Everything should pass. If it does not, say so in an issue rather than
working around it.

## Add a character

Four images and one line of Swift.

1. Generate the poses. `Art/reference/PROMPTS.md` has the brief and the exact
   prompts, including the walk cycle, which is the part that goes wrong. Save
   them under `Art/reference/<name>/`.
2. Import them:

   ```
   python3 scripts/import_reference.py Art/reference Sources/DeskmatesCore/Resources/sprites
   ```

   The importer slices each strip, matches the sizes, cuts the background and
   writes the sheet. It stops and says what is wrong if the figures touch or
   the count does not match the file name.
3. Give the character a job, in `Stage.job(for:)`:

   ```swift
   case "yourname": return Battery()
   ```

   Leave it out and the character still walks about and does its signature
   pose when clicked.
4. Run it, and check the character against `CHECKS.md`.

The art does not have to be generated. Anything that exports an Aseprite
sprite sheet works, because that is the format the loader reads.

## Add a job

One file in `Sources/DeskmatesCore/Jobs/`.

A job reports a mood. The sprite sheet decides what that mood looks like. So
a job never names a frame, moves a window, or knows which character it
belongs to.

```swift
final class Weather: NSObject, Job {
    static let id = "weather"

    func start(_ emit: @escaping (Mood) -> Void) { emit(.idle) }
    func stop() {}
}
```

The moods are `idle`, `busy`, `alert`, `happy` and `sleep`. A mood with no
art falls back to standing, so check the character you are attaching to has a
pose for what you report.

Three optional parts: `tapped()` for a click, `menuItems()` for the
right-click menu, and `badge` for one short line above the character's head.

Two rules that keep the desktop liveable:

- Report a change, not a state. A job that reports the same mood every poll
  makes a character that never settles.
- `idle` is the only mood that wanders. Anything else holds the character
  still, because a character crossing the screen while it reports a warning
  reads as two things at once.

### Make it checkable

Jobs are checked by driving the real object, so pass the outside world in:

```swift
init(read: @escaping () -> Reading? = Weather.readSensor)
```

Then a check hands it a stub. `Sources/Checks/BatteryChecks.swift` is the
shortest example. Add yours to `Sources/Checks/main.swift`.

There is no `swift test` here. XCTest and swift-testing both ship with Xcode,
and this builds with the Command Line Tools alone, so the checks run as a
program instead.

## What gets merged

- `swift build` and `swift run Checks` pass.
- New behaviour comes with checks that fail without it.
- Comments say why, not what.
- No network calls, no analytics, no permission prompts. A character reads
  the machine in front of it or it does not ship.

## What to work on

Issues marked `good first issue` are real gaps, not made-up work. The art
pipeline, the four unassigned jobs and the missing poses are all listed
there.
