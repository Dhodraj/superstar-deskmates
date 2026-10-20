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

Named after Tamil film actors, matched to what the job feels like. Three ship in
v1, marked below.

| Character | Job | Reads |
|---|---|---|
| Ajith (v1) | Focus timer | Nothing. First job to build. |
| Sivaji (v1) | AI token spend today | `~/.claude/projects/**/*.jsonl`, `~/.codex/sessions/**/rollout-*.jsonl` |
| Manorama | Rate-limit warning | Same files, rolling 5-hour window |
| Vadivelu (v1) | Uncommitted work piling up | `git status --porcelain` on watched repos |
| Arjun | Last CI run | `gh run list --limit 1 --json conclusion` |
| Sathyaraj | What is running now | `NSWorkspace.runningApplications` |
| Vijayakanth | Today's news | One RSS feed, `XMLParser` |
| Delhi Ganesh | Today's commits, at 18:00 | `git log --since=midnight` across repos |
| Goundamani and Senthil | Focus guard, as a pair | Frontmost app during a focus session |

Three on screen at once, as a start. Right-click to swap. Hidden characters stop
their timers rather than hide a view.

One flag on the names: these are living people, and a public repo is a different
thing from a private toy. If that matters later, use Spritefolk's own approach. Name the job in Tamil, so
the timer is `Vilakku` and the paper is `Seithi`. Mapping names to jobs costs one file either way.

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

## Milestones

1. Spike. One panel, one CC0 sprite, idle and walk, alpha hit-test, drag to
   move, right-click to quit. This proves the three parts that can fail: a
   transparent non-activating panel, click-through on transparent pixels, and
   animation that does not burn CPU.
2. Stage. Sheet format with hot reload, `Wanderer`, three panels, menu bar
   item, settings that persist, sleep that stops timers.
3. Jobs. Ajith first, because it reads nothing. Then Sivaji, then the rest.

Two parts will take a day each whatever the plan: per-pixel hit-testing, and
behaviour across several monitors and fullscreen Spaces.

## Open questions

- Which three actors ship in v1?
- Public GitHub repo now, or local until the spike runs?
