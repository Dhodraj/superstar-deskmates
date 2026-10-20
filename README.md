# Superstar Deskmates

Pixel characters that live on your Mac desktop. Each one does a single job and
reads nothing but the machine in front of it.

Three characters ship today, drawn after Tamil film actors.

| Character | Job | What you see |
|---|---|---|
| Vijay | Focus timer | Click him to start. He folds his arms for the session, reacts if you leave the app you started in, and waves when it ends |
| Ajit | Battery | Helmet on while the Mac charges, hands up when the charge runs low |
| Rajni | What is running | Counts the apps you have open, and flips his coin once the desk is crowded |

No account, no network, no permission prompts. Nothing leaves the Mac.

## Running it

Needs macOS 14 or later and the Xcode Command Line Tools.

```
./scripts/make_app.sh
open build/Deskmates.app
```

That builds `Deskmates.app`. No Dock icon, a cutout figure for an icon, and
an ad-hoc signature. That signature is enough to run on the Mac
that built it. Move it to `/Applications` and the menu bar gains a **Start at
login** entry.

Shipping it to anyone else needs a Developer ID and notarisation, which this
does not have yet.

For a quick run during development, skip the bundle:

```
swift build && ./.build/debug/Deskmates
```

There is no Dock icon. The menu bar item is the way in when every character is
hidden, and a right-click on a character does the same.

Drag a character to move it. Click it to talk to its job. Clicks pass through
the transparent pixels around it, so the window behind still gets them.

## Settings

All through the environment, because there is nowhere else yet.

| Variable | What it does |
|---|---|
| `DESKMATES_SCALE` | How large the characters are. 1 by default. Prefer 0.5 or 1 |
| `DESKMATES_SPEED` | Walking speed in points per second. 11 by default |
| `DESKMATES_FOCUS` | Focus session length in minutes. 25 by default |
| `DESKMATES_DISTRACTIONS` | Apps Vijay treats as drift, by bundle identifier |
| `DESKMATES_BATTERY_LOW` | Charge at which Ajit puts his hands up. 20 by default |
| `DESKMATES_APPS_BUSY` | Apps open before Rajni starts counting. 8 by default |
| `DESKMATES_APPS_CROWDED` | Apps open before Rajni flips his coin. 14 by default |
| `DESKMATES_SPRITES` | Read art from a folder instead of the bundle |
| `DESKMATES_DEBUG` | Print each character's position and every mood change |

## Art

The characters are drawn from reference images, one sprite sheet row per
character. `Art/reference/PROMPTS.md` holds the brief that produced them, and
the importer turns them into sheets:

```
python3 scripts/import_reference.py Art/reference Sources/DeskmatesCore/Resources/sprites
```

Sheets use Aseprite's own JSON, so a character drawn by hand drops in the same
way.

## Checks

```
swift run Checks
```

The jobs are covered there. Anything needing a cursor is in `CHECKS.md`.

## How it is put together

`DESIGN.md` has the reasoning. The short version: a job reports a mood, and the
sprite sheet decides what that looks like. A job never names a frame, moves a
window, or knows which character it belongs to. Art and behaviour can be
replaced one at a time.

## Credits

Inspired by [Spritefolk](https://spritefolk.com/), a paid closed-source Mac app
with the same idea. This is a clean build from observed behaviour, not a port.

The characters are caricatures of living people. If that ever becomes a
problem, the art stays and the names go.

MIT licensed.
