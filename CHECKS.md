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
DESKMATES_DEBUG=1 DESKMATES_FOCUS=1 ./.build/debug/Deskmates
```

`DESKMATES_DEBUG` prints a position line once a second and a `mood` line
whenever a character changes mood. `DESKMATES_FOCUS=1` makes a focus session
one minute instead of 25.

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

## Ajit, the battery

| Check | What to do | What should happen |
|---|---|---|
| Reads the charge | Right-click Ajit | `Battery <n>%, <h:mm> left`, matching the menu bar |
| Charging | Plug the Mac in | Helmet on within 30 seconds. The log prints `mood ajit busy` |
| Unplugging | Pull the cable | Helmet off, back to wandering |
| Nearly empty | Start with `DESKMATES_BATTERY_LOW=95` on an unplugged Mac | Hands up. The log prints `mood ajit alert` |
| No battery | Run it on a Mac with no battery | `No battery` in the menu, and he wanders. He must not look empty |

## Rajni, what is running

| Check | What to do | What should happen |
|---|---|---|
| Counts the apps | Right-click Rajni | `<n> apps, front: <name>`, then the list |
| Matches reality | Count your Dock | The same apps. Background helpers are not counted |
| Front app | Click another app, then right-click him | The front name follows |
| Filling up | Start with `DESKMATES_APPS_BUSY=2` | He counts notes. The log prints `mood rajni busy` |
| Crowded | Start with `DESKMATES_APPS_CROWDED=3` | He flips the coin. The log prints `mood rajni alert` |
| Clearing | Quit apps until you are under the line | Back to wandering |
| Long list | Open more than ten apps | The menu lists ten, then `and <n> more` |

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
