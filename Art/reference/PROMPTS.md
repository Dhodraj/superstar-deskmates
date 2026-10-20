# Reference prompts

Two strips per character. The first replaces the strip already in the folder,
because its two walking figures stand the same way. The second adds the moods
the jobs need.

Attach that character's single image to every prompt, so the face and clothes
carry across the poses:

- `Art/reference/vijay.png`
- `Art/reference/ajit.png`
- `Art/reference/rajni.png`

Save each result at the path given, then rebuild the sheets:

```
python3 scripts/import_reference.py Art/reference Sources/DeskmatesCore/Resources/sprites
```

The importer reads every `strip-*.png` in a character's folder and scales them
all together. It slices a strip at the empty columns between figures, and takes
the tags from the file name. So the figures must not touch, and the order in
the image must match the order in the name.

One image per character also works. Put all the poses in a single strip, and
name it for them in order. The importer does not care how many files there
are.

## The walk cycle

This is what went wrong twice. The first prompt asked for "left foot forward"
and then "right foot forward". The second added arms and the word mirror. Both
produced two figures that stand the same way.

The wording was not the real problem. The camera was. These figures face the
camera, and from the front a leg put forward is almost hidden behind the body.
Left leg forward and right leg forward make nearly the same shape, so there is
nothing for the model to draw differently. A mirror of a front view is a front
view.

What reads from the front is a foot off the ground. Describe the walk by which
foot is lifted, not by which leg is forward:

> Figures 2 and 3 are two moments of one walk, seen from the front. They must
> not look the same.
>
> In figure 2 the left foot is flat on the ground and carries his weight. The
> right knee is raised in front of him, so the right foot hangs clearly off the
> ground at about shin height. His left arm swings forward and his right arm
> swings back.
>
> In figure 3 the right foot is flat on the ground and carries his weight. The
> left knee is raised in front of him, so the left foot hangs clearly off the
> ground at about shin height. His right arm swings forward and his left arm
> swings back.
>
> Do not copy figure 2 into figure 3. Before you finish, check the feet: figure
> 2 has the right foot in the air, figure 3 has the left foot in the air. If
> both figures have both feet on the ground, the walk is wrong.

### If it still comes back the same

Generate the two walk poses as two images rather than as part of a strip, one
pose per prompt. The importer reads single-pose files as well as strips, and
the tag comes from the file name before the dash:

    Art/reference/vijay/walk-a.png
    Art/reference/vijay/walk-b.png

Then ask for the strip without its walking figures, and name it for what is
left: `strip-idle-happy.png`.

Do not ask for a side view of the walk and a front view of everything else.
The character would turn on the spot every time it started walking.

## Shared rules

Every prompt below ends with this block. It is the same for all of them:

> Same camera distance and the same body height for all figures, with their
> feet on one baseline. Clear empty space between the figures, so none of them
> touch or overlap. Plain flat off-white background, no gradient and no shadow
> on the floor. Nothing else in the scene. A dark outline around each figure.
> Front view.

## Strip 1: standing, walking, signature

This replaces the file already in each folder.

### Vijay

Save as `Art/reference/vijay/strip-idle-walk-walk-happy.png`.

> Pixel art sprite strip of the same man as the attached image. Four full-body
> figures in one horizontal row.
>
> Figure 1 stands still with his arms down.
>
> Figures 2 and 3 are two moments of one walk, seen from the front. They must
> not look the same. In figure 2 the left foot is flat on the ground and
> carries his weight, the right knee is raised in front of him so the right
> foot hangs clearly off the ground at about shin height, his left arm swings
> forward and his right arm swings back. In figure 3 the right foot is flat on
> the ground and carries his weight, the left knee is raised in front of him so
> the left foot hangs clearly off the ground at about shin height, his right
> arm swings forward and his left arm swings back. Do not copy figure 2 into
> figure 3. Before you finish, check the feet: figure 2 has the right foot in
> the air, figure 3 has the left foot in the air.
>
> Figure 4 waves with one arm raised high.
>
> Keep his face, hair, headband, scarf and clothes exactly as in the attached
> image. Drop the stage, the railing and the lights. Show only the man, head to
> shoes.
>
> Same camera distance and the same body height for all figures, with their
> feet on one baseline. Clear empty space between the figures, so none of them
> touch or overlap. Plain flat off-white background, no gradient and no shadow
> on the floor. Nothing else in the scene. A dark outline around each figure.
> Front view.

### Ajit

Save as `Art/reference/ajit/strip-idle-walk-walk-busy.png`.

> Pixel art sprite strip of the same man as the attached image. Four full-body
> figures in one horizontal row.
>
> Figure 1 stands still with his arms down.
>
> Figures 2 and 3 are two moments of one walk, seen from the front. They must
> not look the same. In figure 2 the left foot is flat on the ground and
> carries his weight, the right knee is raised in front of him so the right
> foot hangs clearly off the ground at about shin height, his left arm swings
> forward and his right arm swings back. In figure 3 the right foot is flat on
> the ground and carries his weight, the left knee is raised in front of him so
> the left foot hangs clearly off the ground at about shin height, his right
> arm swings forward and his left arm swings back. Do not copy figure 2 into
> figure 3. Before you finish, check the feet: figure 2 has the right foot in
> the air, figure 3 has the left foot in the air.
>
> Figure 4 lifts the racing helmet to put it on.
>
> Keep his face, grey hair and beard, white race suit and red boots exactly as
> in the attached image.
>
> Same camera distance and the same body height for all figures, with their
> feet on one baseline. Clear empty space between the figures, so none of them
> touch or overlap. Plain flat off-white background, no gradient and no shadow
> on the floor. Nothing else in the scene. A dark outline around each figure.
> Front view.

### Rajni

Save as `Art/reference/rajni/strip-idle-walk-walk-alert.png`.

> Pixel art sprite strip of the same man as the attached image. Four full-body
> figures in one horizontal row.
>
> Figure 1 stands still with his arms down.
>
> Figures 2 and 3 are two moments of one walk, seen from the front. They must
> not look the same. In figure 2 the left foot is flat on the ground and
> carries his weight, the right knee is raised in front of him so the right
> foot hangs clearly off the ground at about shin height, his left arm swings
> forward and his right arm swings back. In figure 3 the right foot is flat on
> the ground and carries his weight, the left knee is raised in front of him so
> the left foot hangs clearly off the ground at about shin height, his right
> arm swings forward and his left arm swings back. Do not copy figure 2 into
> figure 3. Before you finish, check the feet: figure 2 has the right foot in
> the air, figure 3 has the left foot in the air.
>
> Figure 4 flips a coin from one hand, chin lifted.
>
> Keep his face, sunglasses, hair and tan suit exactly as in the attached
> image. The attached image stops at his chest. Show him head to shoes, in the
> same suit.
>
> Same camera distance and the same body height for all figures, with their
> feet on one baseline. Clear empty space between the figures, so none of them
> touch or overlap. Plain flat off-white background, no gradient and no shadow
> on the floor. Nothing else in the scene. A dark outline around each figure.
> Front view.

## Strip 2: the moods the jobs need

A job reports a mood, and a mood the sheet does not have falls back to
standing. So a character shows nothing where it should warn you. Ajit is the
worst case today: his job reports a failed build, and he stands there.

| Character | Has | Needs | Why |
|---|---|---|---|
| Vijay | idle, walk, happy | busy | Standing at work while a focus session runs |
| Ajit | idle, walk, busy | alert, happy | A failed run, and the wave when it goes green |
| Rajni | idle, walk, alert | busy | Counting while the tokens add up |

Save these beside the first strip.

### Vijay

Save as `Art/reference/vijay/strip-busy.png`.

> Pixel art of the same man as the attached image. One full-body figure,
> standing still with his arms folded, watching. Patient, not pleased.
>
> Keep his face, hair, headband, scarf and clothes exactly as in the attached
> image. Drop the stage, the railing and the lights.
>
> Plain flat off-white background, no gradient and no shadow on the floor.
> Nothing else in the scene. A dark outline around the figure. Front view, head
> to shoes, at the same camera distance as the other images in this set.

### Ajit

Save as `Art/reference/ajit/strip-alert-happy.png`.

> Pixel art sprite strip of the same man as the attached image. Two full-body
> figures in one horizontal row. Figure 1 has both hands raised in
> frustration. Figure 2 punches the air with one fist.
>
> Keep his face, grey hair and beard, white race suit and red boots exactly as
> in the attached image.
>
> Same camera distance and the same body height for both figures, with their
> feet on one baseline. Clear empty space between them, so they do not touch.
> Plain flat off-white background, no gradient and no shadow on the floor.
> Nothing else in the scene. A dark outline around each figure. Front view.

### Rajni

Save as `Art/reference/rajni/strip-busy.png`.

> Pixel art of the same man as the attached image. One full-body figure,
> counting banknotes in both hands, head down.
>
> Keep his face, sunglasses, hair and tan suit exactly as in the attached
> image. Show him head to shoes.
>
> Plain flat off-white background, no gradient and no shadow on the floor.
> Nothing else in the scene. A dark outline around the figure. Front view, at
> the same camera distance as the other images in this set.

## If a strip comes back wrong

- Both walking figures stand the same way: the walk will not animate. Ask
  again, and say which foot is off the ground in each figure. A leg put forward
  does not read from the front; a lifted foot does.
- Figures touching: the importer counts the wrong number and stops with a
  message. Ask again for more space between them.
- One figure taller than the rest: the importer scales the whole strip by its
  tallest figure, so a tall pose shrinks the others. Ask again for one body
  height.
- Scenery kept: ask again with the scenery named. Anything touching a figure
  survives the background cut, because the cut floods in from the border and
  stops at the figure's outline.
