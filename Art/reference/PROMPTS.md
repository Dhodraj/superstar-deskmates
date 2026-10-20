# Reference prompts

Seven images, two or three per character. Each one is a sprite sheet row: a line of
full-body figures that become the frames of an animation.

Save them here, then rebuild the sheets:

```
python3 scripts/import_reference.py Art/reference Sources/DeskmatesCore/Resources/sprites
```

| Save as | Figures |
|---|---|
| `vijay/strip-anchor-idle-idle-walk-walk-walk-walk.png` | 7 |
| `vijay/strip-anchor-happy-happy-busy-busy.png` | 5 |
| `vijay/strip-anchor-alert-alert.png` | 3 |
| `ajit/strip-anchor-idle-idle-walk-walk-walk-walk.png` | 7 |
| `ajit/strip-anchor-busy-busy-alert-alert-happy-happy.png` | 7 |
| `rajni/strip-anchor-idle-idle-walk-walk-walk-walk.png` | 7 |
| `rajni/strip-anchor-alert-alert-busy-busy.png` | 5 |

Delete what is in each folder first. The importer reads every `strip-*.png` it
finds, so an old file is imported alongside the new one.

Attach that character's single image to every prompt:
`Art/reference/vijay.png`, `ajit.png`, `rajni.png`.

## How the frames are used

Each figure becomes one frame, 192 pixels tall, drawn on the desktop at about
twice that in physical pixels. The frames play in the order they appear, left
to right, and loop:

| Animation | Frames | Each frame holds |
|---|---|---|
| idle | 2 | 500 ms |
| walk | 4 | 260 ms |
| happy, busy, alert | 2 | 300 to 400 ms |

Two frames at half a second is a slow loop. It reads as a person breathing,
not as animation. That is what it should be: a character standing in the
corner of a screen all day.

The importer crops each figure to its own paint and stands it on the floor of
its frame. So a figure that rises in the pose rises on screen, and a lifted
foot leaves the ground. Nothing needs aligning by hand.

## The anchor

Every image starts with the same figure: the character standing plainly, feet
together, arms straight down, head level, facing the camera. That is the
anchor. It is never shown. The importer measures it, matches the two images to
one size, and throws it away.

This exists because two images generated separately come back at different
camera distances. We asked for the same distance and got a character 40 per
cent larger in the second image. An anchor in both images is something to
measure, so the distance no longer has to be guessed.

The anchor must be the same pose in both of a character's images. If it
drifts, the two animations end up at different sizes.

## The walk cycle

A walk cycle has four key poses: contact, down, passing and up. Eight frames
is the usual full set. Four frames is the standard reduction, keeping the two
contacts and the two passings, and that is what these sheets use.

Two earlier attempts failed here. Asking for "left foot forward" and then
"right foot forward" produced two identical figures. These characters face the camera, and a leg put
forward is hidden behind the body. From the front the two contact poses do
look alike. What separates the frames is the passing
pose, where one knee comes up and the foot leaves the ground.

The cycle alternates wide, knee up, wide, other knee up:

| Frame | Pose | Feet | Arms | Body height |
|---|---|---|---|---|
| 1 | Contact | Apart, right foot forward and flat, left foot back with the heel lifted | Left arm forward, right arm back | Lowest |
| 2 | Passing | Right foot flat under him taking the weight, left knee raised in front, left foot off the ground at shin height | Both near his sides, mid-swing | Highest |
| 3 | Contact | Apart, left foot forward and flat, right foot back with the heel lifted | Right arm forward, left arm back | Lowest |
| 4 | Passing | Left foot flat under him taking the weight, right knee raised in front, right foot off the ground at shin height | Both near his sides, mid-swing | Highest |

The body height matters as much as the legs. A walk rises and falls across the
cycle, lowest when both feet are down and highest when one leg swings through.
Without it the character glides.

## Shared rules

Every prompt below ends with this block:

> Side by side in one horizontal row, evenly spaced, with clear empty space
> between the figures so none of them touch or overlap. The same camera
> distance, the same eye level and the same lighting for every figure. Plain
> flat off-white background, one colour, no gradient, no shadow on the floor
> and nothing else in the scene. A dark outline around each figure. No motion
> blur, no speed lines, no ghosting. Pixel art, the same palette and the same
> level of detail as the attached image.

## Vijay

### Movement

Save as `Art/reference/vijay/strip-anchor-idle-idle-walk-walk-walk-walk.png`.

> Pixel art sprite sheet of the same man as the attached image, seven
> full-body figures facing the camera.
>
> Figure 1 is a reference pose: standing plainly, feet together, arms straight
> down at his sides, head level.
>
> Figures 2 and 3 are one breath. Figure 2 stands at rest, weight even on both
> feet, arms hanging. Figure 3 is the same pose breathing in: chest and
> shoulders lifted a little, head a little higher. Nothing else changes
> between them.
>
> Figures 4 to 7 are one walk cycle. Figure 4: feet apart, right foot forward
> and flat on the ground, left foot behind with the heel lifted, left arm
> swung forward, right arm back, body at its lowest. Figure 5: right foot flat
> under him carrying his weight, left knee raised in front so the left foot
> hangs clear of the ground at shin height, arms near his sides, body at its
> highest. Figure 6: feet apart, left foot forward and flat, right foot behind
> with the heel lifted, right arm swung forward, left arm back, body at its
> lowest. Figure 7: left foot flat under him carrying his weight, right knee
> raised in front so the right foot hangs clear of the ground at shin height,
> arms near his sides, body at its highest.
>
> Keep his face, hair, headband, scarf and clothes exactly as in the attached
> image. Drop the stage, the railing and the lights. Show only the man, head
> to shoes.
>
> Side by side in one horizontal row, evenly spaced, with clear empty space
> between the figures so none of them touch or overlap. The same camera
> distance, the same eye level and the same lighting for every figure. Plain
> flat off-white background, one colour, no gradient, no shadow on the floor
> and nothing else in the scene. A dark outline around each figure. No motion
> blur, no speed lines, no ghosting. Pixel art, the same palette and the same
> level of detail as the attached image.

### Moods

Save as `Art/reference/vijay/strip-anchor-happy-happy-busy-busy.png`.

> Pixel art sprite sheet of the same man as the attached image, five full-body
> figures facing the camera.
>
> Figure 1 is a reference pose: standing plainly, feet together, arms straight
> down at his sides, head level.
>
> Figures 2 and 3 are one wave. Figure 2 has his right arm raised above his
> head, palm open, hand tilted to his right. Figure 3 is the same raised arm
> tilted to his left, as though the hand is crossing back. His feet and body
> do not move between them.
>
> Figures 4 and 5 are waiting. Figure 4 stands with his arms folded across his
> chest, weight on one leg, watching. He is patient, not pleased. Figure 5 is
> the same pose breathing in, shoulders lifted a little. Nothing else changes.
>
> Keep his face, hair, headband, scarf and clothes exactly as in the attached
> image. Drop the stage, the railing and the lights. Show only the man, head
> to shoes.
>
> Side by side in one horizontal row, evenly spaced, with clear empty space
> between the figures so none of them touch or overlap. The same camera
> distance, the same eye level and the same lighting for every figure. Plain
> flat off-white background, one colour, no gradient, no shadow on the floor
> and nothing else in the scene. A dark outline around each figure. No motion
> blur, no speed lines, no ghosting. Pixel art, the same palette and the same
> level of detail as the attached image.

## Ajit

### Movement

Save as `Art/reference/ajit/strip-anchor-idle-idle-walk-walk-walk-walk.png`.

> Pixel art sprite sheet of the same man as the attached image, seven
> full-body figures facing the camera.
>
> Figure 1 is a reference pose: standing plainly, feet together, arms straight
> down at his sides, head level, both hands empty.
>
> Figures 2 and 3 are one breath. Figure 2 stands at rest, weight even on both
> feet, arms hanging. Figure 3 is the same pose breathing in: chest and
> shoulders lifted a little, head a little higher. Nothing else changes
> between them.
>
> Figures 4 to 7 are one walk cycle. Figure 4: feet apart, right foot forward
> and flat on the ground, left foot behind with the heel lifted, left arm
> swung forward, right arm back, body at its lowest. Figure 5: right foot flat
> under him carrying his weight, left knee raised in front so the left foot
> hangs clear of the ground at shin height, arms near his sides, body at its
> highest. Figure 6: feet apart, left foot forward and flat, right foot behind
> with the heel lifted, right arm swung forward, left arm back, body at its
> lowest. Figure 7: left foot flat under him carrying his weight, right knee
> raised in front so the right foot hangs clear of the ground at shin height,
> arms near his sides, body at its highest.
>
> Keep his face, grey hair and beard, white race suit and red boots exactly as
> in the attached image. He carries no helmet in any of these figures.
>
> Side by side in one horizontal row, evenly spaced, with clear empty space
> between the figures so none of them touch or overlap. The same camera
> distance, the same eye level and the same lighting for every figure. Plain
> flat off-white background, one colour, no gradient, no shadow on the floor
> and nothing else in the scene. A dark outline around each figure. No motion
> blur, no speed lines, no ghosting. Pixel art, the same palette and the same
> level of detail as the attached image.

### Moods

Save as `Art/reference/ajit/strip-anchor-busy-busy-alert-alert-happy-happy.png`.

> Pixel art sprite sheet of the same man as the attached image, seven
> full-body figures facing the camera.
>
> Figure 1 is a reference pose: standing plainly, feet together, arms straight
> down at his sides, head level, both hands empty.
>
> Figures 2 and 3 put the helmet on. Figure 2 holds the racing helmet in both
> hands at chest height, looking down at it. Figure 3 has lifted it above his
> head with both hands, about to lower it on.
>
> Figures 4 and 5 are frustration. Figure 4 has both hands raised to the sides
> of his head, elbows out, mouth open. Figure 5 has dropped his hands to his
> hips, head tipped back, looking up.
>
> Figures 6 and 7 are celebration. Figure 6 punches one fist up above his
> head. Figure 7 has both fists up and his feet slightly apart, mid-cheer.
>
> Keep his face, grey hair and beard, white race suit and red boots exactly as
> in the attached image.
>
> Side by side in one horizontal row, evenly spaced, with clear empty space
> between the figures so none of them touch or overlap. The same camera
> distance, the same eye level and the same lighting for every figure. Plain
> flat off-white background, one colour, no gradient, no shadow on the floor
> and nothing else in the scene. A dark outline around each figure. No motion
> blur, no speed lines, no ghosting. Pixel art, the same palette and the same
> level of detail as the attached image.

## Rajni

### Movement

Save as `Art/reference/rajni/strip-anchor-idle-idle-walk-walk-walk-walk.png`.

> Pixel art sprite sheet of the same man as the attached image, seven
> full-body figures facing the camera.
>
> Figure 1 is a reference pose: standing plainly, feet together, arms straight
> down at his sides, head level.
>
> Figures 2 and 3 are one breath. Figure 2 stands at rest, weight even on both
> feet, arms hanging. Figure 3 is the same pose breathing in: chest and
> shoulders lifted a little, head a little higher. Nothing else changes
> between them.
>
> Figures 4 to 7 are one walk cycle. Figure 4: feet apart, right foot forward
> and flat on the ground, left foot behind with the heel lifted, left arm
> swung forward, right arm back, body at its lowest. Figure 5: right foot flat
> under him carrying his weight, left knee raised in front so the left foot
> hangs clear of the ground at shin height, arms near his sides, body at its
> highest. Figure 6: feet apart, left foot forward and flat, right foot behind
> with the heel lifted, right arm swung forward, left arm back, body at its
> lowest. Figure 7: left foot flat under him carrying his weight, right knee
> raised in front so the right foot hangs clear of the ground at shin height,
> arms near his sides, body at its highest.
>
> Keep his face, sunglasses, hair and tan suit exactly as in the attached
> image. The attached image stops at his chest, so show him head to shoes in
> the same suit, with dark shoes.
>
> Side by side in one horizontal row, evenly spaced, with clear empty space
> between the figures so none of them touch or overlap. The same camera
> distance, the same eye level and the same lighting for every figure. Plain
> flat off-white background, one colour, no gradient, no shadow on the floor
> and nothing else in the scene. A dark outline around each figure. No motion
> blur, no speed lines, no ghosting. Pixel art, the same palette and the same
> level of detail as the attached image.

### Moods

Save as `Art/reference/rajni/strip-anchor-alert-alert-busy-busy.png`.

> Pixel art sprite sheet of the same man as the attached image, five full-body
> figures facing the camera.
>
> Figure 1 is a reference pose: standing plainly, feet together, arms straight
> down at his sides, head level.
>
> Figures 2 and 3 are one coin flip. Figure 2 has his right hand at chest
> height, thumb against his fingers, a coin resting on the thumb, chin lifted.
> Figure 3 has the same hand open after the flick, with the coin in the air
> above it, near his shoulder. His feet do not move between them.
>
> Figures 4 and 5 are counting. Figure 4 holds a small stack of banknotes in
> his left hand and draws one off with his right, head down. Figure 5 is the
> same, one note further on, his right hand lower.
>
> Keep his face, sunglasses, hair and tan suit exactly as in the attached
> image. Show him head to shoes, with dark shoes.
>
> Side by side in one horizontal row, evenly spaced, with clear empty space
> between the figures so none of them touch or overlap. The same camera
> distance, the same eye level and the same lighting for every figure. Plain
> flat off-white background, one colour, no gradient, no shadow on the floor
> and nothing else in the scene. A dark outline around each figure. No motion
> blur, no speed lines, no ghosting. Pixel art, the same palette and the same
> level of detail as the attached image.

## Vijay still needs one more

His job reacts when you leave the app you started in, and that reaction has no
pose. He reports `alert` and the sheet has none, so he falls back to standing
and the moment reads as nothing.

Save as `Art/reference/vijay/strip-anchor-alert-alert.png`.

> Pixel art sprite sheet of the same man as the attached image, three full-body
> figures facing the camera.
>
> Figure 1 is a reference pose: standing plainly, feet together, arms straight
> down at his sides, head level.
>
> Figures 2 and 3 are one disappointed look. Figure 2 has both arms out from
> his sides, elbows bent, palms turned up, head tilted, eyebrows raised, as
> though asking where you went. Figure 3 is the same pose with his arms a
> little lower and his head tilted the other way. His feet do not move between
> them.
>
> Keep his face, hair, headband, scarf and clothes exactly as in the attached
> image. Drop the stage, the railing and the lights. Show only the man, head
> to shoes.
>
> Side by side in one horizontal row, evenly spaced, with clear empty space
> between the figures so none of them touch or overlap. The same camera
> distance, the same eye level and the same lighting for every figure. Plain
> flat off-white background, one colour, no gradient, no shadow on the floor
> and nothing else in the scene. A dark outline around each figure. No motion
> blur, no speed lines, no ghosting. Pixel art, the same palette and the same
> level of detail as the attached image.

Attach `Art/reference/vijay.png`, the same image as his other two prompts. The
anchor is what keeps all three sheets at one size.

## Checking a sheet before you import it

Ask again when any of these is true:

- The figure count is wrong. The importer stops and says what it counted.
- Two figures touch. They are read as one, so the count comes out short.
- Both contact frames look the same, or neither passing frame lifts a foot.
  The walk will not read.
- The body does not rise and fall across the walk. The character will glide.
- The anchor is missing, or it is a different pose in the character's two
  images. The two animations end up at different sizes.
- One figure is much larger than the rest. The importer prints a warning and
  names the file.
- Scenery came along. Anything touching a figure survives the background cut,
  because the cut floods in from the border and stops at the figure's outline.
- The palette drifted between the two images, most often the skin or the suit.
