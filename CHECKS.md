# Checking it by hand

The checks that run as a program cover the jobs. They cannot cover anything
that needs a cursor: clicking a character, opening a menu, dragging, or seeing
an animation play. This is that list.

Run everything from the repository root.

## Automatic first

```
swift run Checks
```

Expect `all checks passed`. Nothing below is worth doing if this fails.

## Start with everything visible

```
rm -f ~/Library/Application\ Support/Deskmates/settings.json
swift build
DESKMATES_DEBUG=1 DESKMATES_FOCUS=1 DESKMATES_SPEND_ALERT=0.01 ./.build/debug/Deskmates
```

`DESKMATES_DEBUG` prints a position line once a second and a `mood` line
whenever a character changes mood. `DESKMATES_FOCUS=1` makes a focus session
one minute instead of 25. `DESKMATES_SPEND_ALERT=0.01` makes Rajni treat any
spending day as heavy, so his alert pose shows at once.

Stop it with ctrl-C. Positions are saved on the way out.

## The stage

| Check | What to do | What should happen |
|---|---|---|
| Three characters | Look at the bottom right | Vijay, Ajit and Rajni, standing on one line |
| Breathing | Watch one for ten seconds | Shoulders lift and fall, about one breath a second |
| Walking | Watch for a minute | Each wanders sideways, legs alternating, body rising on each step |
| Facing | Watch one walk left | It faces the way it is going |
| No overlap | Watch two meet | The walker stops short and waits. They never stand on top of each other |
| Click-through | Click the empty space beside a character, over a window behind it | The window behind takes the click |
| Dragging | Drag a character by its body | It follows the cursor and walks while dragged |
| Position memory | Drag one somewhere, quit, start again | It comes back where you left it |
| Menu bar | Click the walking figure in the menu bar | A list of the three characters, each ticked |
| Hiding | Untick one | It disappears. Its position line stops printing |
| Right-click | Right-click a character | That character's job entries, then the same list |

## Vijay, the focus timer

With `DESKMATES_FOCUS=1`.

| Check | What to do | What should happen |
|---|---|---|
| Start | Click Vijay | He stops wandering and stands. The log prints `mood vijay busy` |
| Menu | Right-click him | `Stop focus (0:5x left)`, counting down |
| Finish | Wait a minute | He waves, then goes back to wandering. The log prints `happy` then `idle` |
| Stop early | Click him, then click again | Back to wandering, no wave. The log prints `busy` then `idle` |

## Ajit, the CI watch

He reads one repository. This one has no remote, so point him at a real one:

```
DESKMATES_DEBUG=1 DESKMATES_REPO=~/path/to/a/repo ./.build/debug/Deskmates
```

`gh` must be signed in to the account that can see that repository. Check with
`gh api user -q .login` before you start.

| Check | What to do | What should happen |
|---|---|---|
| Reads the run | Right-click Ajit | `CI passed: <run name>`, or failed, or running |
| No gh | Point `DESKMATES_REPO` at a folder with no remote | `CI unknown: gh did not answer`. He stands, he does not look green |
| Failure | Point him at a repo whose last run failed | Hands to his head. The log prints `mood ajit alert` |
| In progress | Push something, then click him | Helmet on. The log prints `busy` |
| Recovery | Let a failed run go green, click him | He punches the air once, then stands |

## Rajni, the token spend

| Check | What to do | What should happen |
|---|---|---|
| Today's figures | Right-click Rajni | `Today: <n> tokens, $<n>` |
| Matches reality | Compare against your own count of today's transcripts | The same figures |
| Heavy day | Start with `DESKMATES_SPEND_ALERT=0.01` | He flips a coin. The log prints `mood rajni alert` |
| Quiet day | Start with `DESKMATES_SPEND_ALERT=10000` | He counts notes while a transcript is being written, otherwise he wanders |

## Art

| Check | What to do | What should happen |
|---|---|---|
| Hot reload | Start with `DESKMATES_SPRITES=$PWD/Sources/DeskmatesCore/Resources/sprites`, then re-run the importer | The characters change on screen without a rebuild |
| Crisp pixels | Look closely at an edge | Square pixels, no blur |
| Pale desktop | Put a white window behind a character | The dark outline still separates it from the background |

## Two screens and Spaces

| Check | What to do | What should happen |
|---|---|---|
| Second screen | Drag a character to another display | It keeps walking, and stays inside that screen |
| Spaces | Switch to another desktop | The characters come with you |
| Fullscreen | Put an app fullscreen | Decide what you want here. Today they stay on top |

## What to report back

For anything that fails, the useful detail is the last few `mood` and position
lines from the log, and which table row it was.
