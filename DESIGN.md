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
Sources/Deskmates/
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
| Ajit (v1) | Last CI run | He races in real Formula and endurance events, so the chequered flag is already his. Green flag and red flag are the two states CI has. | All-grey hair and a white beard, white race suit with red and yellow stripes down the outer seams, red boots. Raising the helmet is his `busy` frame. |
| Rajni (v1) | AI token spend | The coin toss in *Sivaji: The Boss* is a money gesture, and critics read his sunglasses as the signal that a character is wealthy. The coin flip is his `alert` frame, for the hour the spend runs high. | Black sunglasses, the strongest identifier available, over dark hair with a grey streak. Tan suit over a patterned tie, brown shoes. |
| Dhanush | Uncommitted work piling up | The persona is the underdog facing forces bigger than him, carried by a lithe frame and fierce delivery. That is the job with the widest mood range. | A narrow body. Proportion is the only full-body cue that works at this size, and it separates him from the other four at a glance. |
| STR | Today's news | The register is charm and satire, which is what a paper read aloud needs. He also changes his look between films, and this job hides most of the face. | Long hair as a block, hands, and a held-up paper. Least face of the five. |

Four jobs stay unassigned for now: the rate-limit warning, what is running
now, today's commits at 18:00, and the focus guard pair. The pair needs two
bodies with opposite proportions, so it needs two more actors.

Three on screen at once, as a start. Right-click to swap. Hidden characters stop
their timers rather than hide a view.

Click a character and it does its signature pose once, then stands again. That
is the whole interaction until the jobs land, and it is also the proof that a
tag plays on demand.

Characters keep 8 points between them. One that walks into another stops and
rests rather than standing on top of it.

One flag on the names. These are living people, and a public repo is a different
thing from a private toy. If it ever becomes a problem, the characters keep their
art and lose their names, and Tamil job words take over.

### Why these three first

Vijay reads no data at all, so the timer proves the stage with no I/O in the way.
Ajit is the cheapest character to draw and his job is one shell call. Rajni is
the job you actually want, and it is the one that parses files. Between them the
three cover every input shape the app will ever have.

## Art

Generated for this project with an image model, one reference per pose, then
imported. Nobody draws pixels by hand unless they want to.

- Size: 192 pixels tall, shown at 96 points. On a Retina display that puts one
  art pixel on one physical pixel.
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

```
swift build && ./.build/debug/Deskmates
```

No Dock icon. The menu bar item is the only way in when every character is
hidden. Right-click a character for the same menu.

Two environment variables:

- `DESKMATES_SPRITES` points at a sprites directory. Set it to
  `Sources/Deskmates/Resources/sprites` while drawing, because hot reload
  cannot watch the copy inside the built bundle.
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
3. Jobs. Vijay first, because the timer reads nothing. Then Ajit, which is one
   shell call. Then Rajni, which parses the usage files.

Two parts will take a day each whatever the plan: per-pixel hit-testing, and
behaviour across several monitors and fullscreen Spaces.

## Open questions

- Which three actors ship in v1?
- Public GitHub repo now, or local until the spike runs?
