# Sprite Folk: design

Pixel characters that live on the macOS desktop. Each character does one job.
Open source, MIT, no paywall, no account, no telemetry.

Inspired by [Spritefolk](https://spritefolk.com/), which is a paid closed-source
Swift app. This is a clean build from observed behaviour, not a port. Nothing is
decompiled or copied.

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

Aseprite's own export. One `.aseprite` source file per character, one tag per
mood, exported with:

```
aseprite -b Art/ajith.aseprite \
  --sheet Resources/sprites/ajith/sheet.png \
  --data  Resources/sprites/ajith/sheet.json \
  --format json-array --list-tags
```

That writes `frames` as a list. Each entry holds a frame rectangle and a
duration in milliseconds. It also writes `meta.frameTags` as a list of
`{name, from, to, direction}`, with zero-based frame indices. The loader reads a mood straight from the tag of
the same name. No bespoke format, and no conversion step.

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
Sources/SpriteFolk/
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
| Vijay (v1) | Focus timer | "Thalapathy" means commander, and the persona is the elder brother who keeps you on track. Dance numbers are the reward on `happy`. | Clean side part, no facial hair, bright shirt. The plainest face of the five, which is what makes him readable next to the others. |
| Ajith (v1) | Last CI run | He races in real Formula and endurance events, so the chequered flag is already his. Green flag and red flag are the two states CI has. | Salt and pepper hair, dithered in two tones, with a beard block. IMDb lists the look as a trademark. A helmet variant covers `busy`. |
| Rajini (v1) | AI token spend | The coin toss in *Sivaji: The Boss* is a money gesture, and critics read his sunglasses as the signal that a character is wealthy. He flips a coin per thousand tokens, and stops flipping at `alert`. | Sunglasses, which is a two-pixel dark bar and the strongest identifier available, over swept-back hair. |
| Dhanush | Uncommitted work piling up | The persona is the underdog facing forces bigger than him, carried by a lithe frame and fierce delivery. That is the job with the widest mood range. | A narrow body. Proportion is the only full-body cue that works at this size, and it separates him from the other four at a glance. |
| STR | Today's news | The register is charm and satire, which is what a paper read aloud needs. He also changes his look between films, and this job hides most of the face. | Long hair as a block, hands, and a held-up paper. Least face of the five. |

Four jobs stay unassigned for now: the rate-limit warning, what is running
now, today's commits at 18:00, and the focus guard pair. The pair needs two
bodies with opposite proportions, so it needs two more actors.

Three on screen at once, as a start. Right-click to swap. Hidden characters stop
their timers rather than hide a view.

One flag on the names. These are living people, and a public repo is a different
thing from a private toy. If it ever becomes a problem, the characters keep their
art and lose their names, and Tamil job words take over.

### Why these three first

Vijay reads no data at all, so the timer proves the stage with no I/O in the way.
Ajith is the cheapest character to draw and his job is one shell call. Rajini is
the job you actually want, and it is the one that parses files. Between them the
three cover every input shape the app will ever have.

## Art brief per job

Assign actors against this. The job decides how much face a character needs, and
some jobs need almost none.

### What survives 32 pixels

Use these. Each one is a block of pixels, not a detail:

- Sunglasses. Two dark pixels, and the strongest single identifier there is.
- Moustache. A bar two or three pixels wide, reads at once.
- Bald against full hair. This changes the whole head outline.
- Hair colour as a flat block, or two tones dithered for salt and pepper.
- Beard as a jaw block.
- Shirt colour. One flat block, and the best way to tell two characters apart.
- Body proportion, tall and thin against short and round. The only full-body cue
  that works.
- A cap or hat, because it changes the head outline.

These do not survive. Spend no frames on them: nose shape, eye shape, skin
shading, age lines, or any hairstyle more specific than a block. Thin
spectacle frames are one pixel wide and usually muddy the face.

### The nine jobs

| Job | Moods used | Frames | How much face it needs | What carries it |
|---|---|---|---|---|
| Last CI run | idle, happy, alert | 9 | Almost none | A flag that changes colour. One body, three pixels repainted. Cheapest character to draw. |
| Today's news | idle, busy | 6 | Almost none | A held-up paper covers the body and most of the face. You see hair and hands. |
| Today's commits at 18:00 | idle, happy | 6 | Low | A notebook and pen. Seen once a day, so draw it last. |
| What is running now | idle, busy | 6 | Low | A head turn, so asymmetric hair or a moustache helps more than expression. |
| Focus timer | idle, busy, happy, sleep | 12 | Low | A steady stance and a held clock or lamp. Calm, not expressive. Good first character. |
| AI token spend | idle, busy, alert | 9 | Low | A number panel does the talking. Formal collar, neat hair, a ledger or coin. |
| Rate-limit warning | idle, alert | 5 | High, on one mood | A raised finger and an open mouth. Cheap in frames, demanding in that one pose. |
| Uncommitted work piling up | idle, busy, alert, sleep | 11 | Highest | Three clearly different expressions, because the mood is the data. Needs an elastic face: big eyes, mobile brows, a sweat drop at `alert`. |
| Focus guard pair | idle, alert, happy, twice | 18 | Medium, twice | Silhouette contrast is the whole design. Tall and thin against short and round, or bald against capped. |

All nine come to 82 frames. Three characters for v1 is about 25 to 30.

## Data sources

Read from this Mac and confirmed, not assumed:

- Claude Code writes `~/.claude/projects/<slug>/*.jsonl`. Lines with
  `type == "assistant"` carry `message.model` and
  `message.usage` with `input_tokens`, `cache_creation_input_tokens`,
  `cache_read_input_tokens` and `output_tokens`.
- A `cost-state` line type also appears in those files. Read it before writing a
  model price table. It may hold the cost already.
- Codex writes `~/.codex/sessions/**/rollout-*.jsonl` with a
  `token_usage_record` line type.

Tail these by byte offset and watch the directory with `DispatchSource`. Never
re-read a whole file.

## Art

Drawn here, not sourced. That removes the licence problem, and it is the only way
to get characters that read as these actors.

- Tool: Aseprite, which exports the sheet and the JSON in one command.
  LibreSprite and Pixelorama are free and export the same shape.
- Size: 32x32 cell. At that size a character is a silhouette, not a portrait.
  Hair, moustache, glasses and shirt colour carry the whole likeness, and three
  or four pixels decide whether it works.
- Budget: five moods per character. `idle` and `sleep` are two frames each,
  `busy` and `happy` four, `alert` three. About 15 frames per character.

Narrow the roster to three for v1. Each extra character is another 15 frames and
another job, and a half-drawn roster reads worse than three finished ones. Pick
actors whose silhouette survives 32 pixels: strong hair, glasses, or a face shape
that still reads when most detail is gone.

Likeness is the one open risk. A 32x32 sprite is far from a portrait, and
caricature of a public figure is normal practice. These are still living people,
and a public repo is not a private toy. If it ever becomes a problem, the characters
keep their art and lose their names, and the Tamil job words take over.

AI-generated frames stay out of the repo and in `.gitignore`. Any borrowed
reference art is recorded in `THIRD_PARTY_ART.md` with its source URL and licence.

## Running it

```
swift build && ./.build/debug/SpriteFolk
```

No Dock icon. The menu bar item is the only way in when every character is
hidden. Right-click a character for the same menu.

Two environment variables:

- `SPRITEFOLK_SPRITES` points at a sprites directory. Set it to
  `Sources/SpriteFolk/Resources/sprites` while drawing, because hot reload
  cannot watch the copy inside the built bundle.
- `SPRITEFOLK_DEBUG` prints every character's position once a second. The app
  has no window to inspect, so this is how you find a character that is not
  where you expect.

Placeholder art is generated, not drawn:

```
python3 scripts/make_placeholder_sheet.py Sources/SpriteFolk/Resources/sprites
```

## Milestones

1. Spike. Done. One panel, a generated sprite, idle and walk, alpha hit-test,
   drag to move, right-click to quit. This proved the three parts that can
   fail: a transparent non-activating panel, click-through on transparent
   pixels, and animation that does not burn CPU.
2. Stage. Done. Sheet format with hot reload, `Wanderer`, three panels, menu
   bar item, settings that persist, sleep that stops timers.
3. Jobs. Vijay first, because the timer reads nothing. Then Ajith, which is one
   shell call. Then Rajini, which parses the usage files.

Two parts will take a day each whatever the plan: per-pixel hit-testing, and
behaviour across several monitors and fullscreen Spaces.

## Open questions

- Which three actors ship in v1?
- Public GitHub repo now, or local until the spike runs?
