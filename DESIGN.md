# Superstar Deskmates: design

Pixel characters that live on the macOS desktop. Each character does one job.
Open source, MIT, no paywall, no account, no telemetry.

Inspired by [Spritefolk](https://spritefolk.com/), which is a paid closed-source
Swift app. This is a clean build from observed behaviour, not a port. Nothing is
decompiled or copied. The name is different for the same reason: Spritefolk is
theirs.

In code the name is plain `Deskmates`: the package, the binary, the
`DESKMATES_` environment variables, and the support folder. Superstar belongs
on the product, not in every path.

## Non-goals

- No licensing, purchases or update server.
- No notarisation or DMG until someone other than me wants to run it.
- No cross-platform layer. AppKit directly.
- No character pretends to be a chat assistant.

## Architecture

Two halves that know almost nothing about each other.

Stage draws and moves characters. One `NSPanel` per character:
`.nonactivatingPanel`, clear background, no shadow, level `.statusBar`,
collection behaviour `[.canJoinAllSpaces, .stationary, .ignoresCycle]`. The
sprite view hit-tests against the bitmap alpha, so clicks pass through
transparent pixels to whatever is behind.

Jobs read the world and report how the character feels. A job never names a
frame or touches a window.

### The mood seam

```swift
enum Mood { case idle, busy, alert, happy, sleep }

protocol Job {
    static var id: String { get }
    func start(_ emit: @escaping (Mood) -> Void)
    func stop()
    func menuItems() -> [NSMenuItem]
}
```

A job emits a mood. The sprite sheet maps moods to animations. This is the only
contract between art and behaviour, so either side can be replaced alone. Art
packs with two animations still work, because a missing mood falls back to
`idle`.

### Sprite sheet format

Aseprite's export, whoever writes it. Frames sit side by side in one PNG. A JSON
file lists each frame rectangle with its duration in milliseconds. It also
carries `meta.frameTags`, which names the ranges. The loader reads a mood straight from the
tag of the same name.

Two things write that shape today.

`scripts/import_reference.py` turns reference images into a sheet. One image per
pose, named for its tag:

```
Art/reference/vijay/idle.png
Art/reference/vijay/walk-a.png
Art/reference/vijay/walk-b.png
Art/reference/vijay/happy.png
```

It cuts the background, crops to the figure, and scales every pose to the same
height. Each frame sits on the floor of its cell, so a raised arm does not make
the character hop.

Aseprite itself, when a character is drawn by hand instead:

```
aseprite -b Art/vijay.aseprite \
  --sheet Resources/sprites/vijay/sheet.png \
  --data  Resources/sprites/vijay/sheet.json \
  --format json-array --list-tags
```

Two things to hold:

- The JSON export has no official specification. It is documented by the
  community and by third-party typings, so pin the Aseprite version and keep one
  loader test against a real exported file.
- Exporting several source files into one JSON restarts tag indices per file,
  which points later tags at the wrong frames. One character per export avoids
  this.

The loader reloads when the file changes, so art work needs no rebuild. A
character with only `idle` still runs, because a missing mood falls back to
`idle`.

### Layout

```
Package.swift                    SwiftPM executable, no .xcodeproj
Sources/Deskmates/main.swift     three lines: calls DeskmatesCore.run()
Sources/Checks/                  runnable checks, see Running it
Sources/DeskmatesCore/
  App.swift                      NSApplication, LSUIElement
  Stage/CharacterPanel.swift     the panel
  Stage/SpriteView.swift         alpha hit-test, frame timer
  Stage/SpriteSheet.swift        PNG and JSON loading, hot reload
  Stage/Wanderer.swift           idle and walk, clamped to visibleFrame
  Jobs/                          one file per job
  Menu/StatusItem.swift          menu bar item
  Store/Settings.swift           JSON in Application Support
Resources/sprites/<name>/
```

## Characters

Five actors, chosen for silhouette as much as for the role. Each one is matched
to the job their screen persona already does. Three ship in v1.

| Character | Job | Why this job | Silhouette |
|---|---|---|---|
| Vijay (v1) | Focus timer | "Thalapathy" means commander, and the persona is the elder brother who keeps you on track. Dance numbers are the reward on `happy`. | Red headband over dark hair, moustache and goatee, white shirt and trousers, a red and yellow scarf down the chest, bare forearms. Waving is his `happy` frame. |
| Ajit (v1) | Battery | He races in real Formula and endurance events, so watching the fuel is already his. Charging, running down, nearly empty. | All-grey hair and a white beard, white race suit with red and yellow stripes down the outer seams, red boots. Raising the helmet is his `busy` frame. |
| Rajni (v1) | What is running | The persona is the arrival everyone notices, so noticing who else is in the room suits him. The coin toss from *Sivaji: The Boss* is his `alert` frame, for a crowded desk. | Black sunglasses, the strongest identifier available, over dark hair with a grey streak. Tan suit over a patterned tie, brown shoes. |
| Dhanush | Uncommitted work piling up | The persona is the underdog facing forces bigger than him, carried by a lithe frame and fierce delivery. That is the job with the widest mood range. | A narrow body. Proportion is the only full-body cue that works at this size, and it separates him from the other four at a glance. |
| STR | Today's news | The register is charm and satire, which is what a paper read aloud needs. He also changes his look between films, and this job hides most of the face. | Long hair as a block, hands, and a held-up paper. Least face of the five. |

Four jobs stay unassigned for now: the rate-limit warning, what is running
now, today's commits at 18:00, and the focus guard pair. The pair needs two
bodies with opposite proportions, so it needs two more actors.

Three on screen at once, as a start. Right-click to swap. Hidden characters stop
their timers rather than hide a view.

Click a character with no job and it does its signature pose once, then stands
again. Click one with a job and the click goes to the job instead.

Each job earns its character by reacting at the moment that matters, rather
than waiting to be asked. A state that stays the same changes nothing on
screen.

Vijay keeps a focus session honest. Click him to start. He folds his arms and
stops wandering, and the menu counts down. If you leave the app you started in
and stay away for twenty seconds, he reacts. He settles again when
you come back, and waves when the session ends. A glance at another window is
not drifting, which is what the twenty seconds are for.

`DESKMATES_DISTRACTIONS` narrows what counts, as a comma separated list matched
against the bundle identifier. Without it, any app other than the one the
session started in counts.

Ajit watches the battery, which is the fuel gauge a racer would watch. Helmet
on while the Mac is charging, hands up below the warning level, and the charge
and the time left in his menu. A Mac with no battery reads as nothing to
report, so he stands.

Rajni notices who is in the room: the apps you have open and the one in front.
He counts while the desk fills up, and the coin comes out once it is crowded.
His menu lists them. This is the one job copied straight from Spritefolk, where
Dhiru does the same thing.

Every job reads the machine in front of it. None of them opens a network
connection, and none needs a permission prompt.


## Art

The icon and the menu bar mark are a film slate. Both are drawn in code
rather than kept as image files, so they rebuild with the app. `scripts/make_logo.py`
draws the colour icon and `MenuBarMark` draws the one-colour version. Three
other marks were tried first: three characters on a tile, a D monogram and a
theatre curtain. The slate won because it holds its shape at 32 pixels and
says cinema without naming anyone.

The characters are generated with an image model, one reference per pose, then
imported. Nobody draws pixels by hand unless they want to.

- Size: 192 pixels tall, shown at 192 points. On a Retina display that puts
  one art pixel on a 2x2 block of physical pixels.
- Poses per character: `idle`, two walk frames, and one signature pose. Vijay
  waves, Ajit puts the helmet on, Rajni flips a coin.
- Import: `python3 scripts/import_reference.py Art/reference
  Sources/Deskmates/Resources/sprites`

References live in `Art/reference/`. They are generated for this project, so
they carry no third-party licence and ship with the repo. They are not the art:
they are what the art is made from.

Art taken from anyone else, generated or not, is recorded in
`THIRD_PARTY_ART.md`. Give its source URL, and the licence as stated on the page
the day you downloaded it.

Three characters for v1. Each extra character is four more images and another
job, and a half-finished roster reads worse than three finished ones.

## Running it

As an app, which is how it is meant to run:

```
./scripts/make_app.sh
open build/Deskmates.app
```

The script builds the release binary and puts the SwiftPM resource bundle
beside it in `Contents/Resources`. It then draws the icon, writes an `Info.plist`
with `LSUIElement` set, and signs the result ad-hoc. `SMAppService` needs a bundle to register a login
item. So **Start at login** appears in the menu only when the app runs from
one.

The bundle is not notarised and carries no Developer ID, so it runs on the
machine that built it and nowhere else.

For a quick run during development:

```
swift build && ./.build/debug/Deskmates
```

Anything needing a cursor is in `CHECKS.md`: clicking, menus, dragging and the
animations. The rest run as a program, not as `swift test`:

```
swift run Checks
```

Both XCTest and swift-testing ship with Xcode, and this machine has the Command
Line Tools only. `Sources/Checks` drives the real job objects and exits
non-zero when one misbehaves.

No Dock icon. The menu bar item is the only way in when every character is
hidden. Right-click a character for the same menu.

Two environment variables:

- `DESKMATES_SPRITES` points at a sprites directory. Set it to
  `Sources/Deskmates/Resources/sprites` while drawing, because hot reload
  cannot watch the copy inside the built bundle.
- `DESKMATES_SCALE` sets how large the characters are. The default is 1, which
  puts each art pixel on a 2x2 block of physical pixels on a Retina display and
  keeps the edges square. Half steps such as 0.75 make some pixels bigger than
  others, so prefer 0.5 or 1.
- `DESKMATES_SPEED` sets the walking speed in points per second. The default
  is 11.
- `DESKMATES_FOCUS` sets a focus session in minutes. The default is 25, and a
  short one is how you try it without waiting.
- `DESKMATES_DISTRACTIONS` lists the apps Vijay treats as drift.
- `DESKMATES_BATTERY_LOW` is the charge at which Ajit puts his hands up. The
  default is 20.
- `DESKMATES_APPS_BUSY` and `DESKMATES_APPS_CROWDED` are the app counts at
  which Rajni starts counting and starts flipping. The defaults are 8 and 14.
- `DESKMATES_DEBUG` prints every character's position once a second. The app
  has no window to inspect, so this is how you find a character that is not
  where you expect.

Rebuild the sheets after changing a reference:

```
python3 scripts/import_reference.py Art/reference Sources/Deskmates/Resources/sprites
```

## Milestones

1. Spike. Done. One panel, a generated sprite, idle and walk, alpha hit-test,
   drag to move, right-click to quit. This proved the three parts that can
   fail: a transparent non-activating panel, click-through on transparent
   pixels, and animation that does not burn CPU.
2. Stage. Done. Sheet format with hot reload, `Wanderer`, three panels, menu
   bar item, settings that persist, sleep that stops timers. Characters keep
   clear of each other, save where they stand, and answer a click.
3. Jobs. Done for the three v1 characters. Vijay runs a focus timer and
   watches whether you keep to it, Ajit watches the battery, Rajni counts the
   apps you have open. All three read only this machine.

Two parts will take a day each whatever the plan: per-pixel hit-testing, and
behaviour across several monitors and fullscreen Spaces.

## Open questions

- Public GitHub repo now, or local for a while longer?
- Does a character need a `sleep` pose, or is hiding it enough?
