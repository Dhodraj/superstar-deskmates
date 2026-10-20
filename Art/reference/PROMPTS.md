# Reference prompts

Three prompts, one per character. Attach that character's existing image to its
prompt, so the face and clothes carry across the new poses.

Save each result at the path given, then rebuild the sheets:

```
python3 scripts/import_reference.py Art/reference Sources/Deskmates/Resources/sprites
```

The importer slices a strip at the empty columns between figures, and takes the
tags from the file name. So the figures must not touch, and the order in the
image must match the order in the name.

## Vijay

Attach `Art/reference/vijay.png`.
Save as `Art/reference/vijay/strip-idle-walk-walk-happy.png`.

> Pixel art sprite strip of the same man as the attached image. Four full-body
> figures in one horizontal row, left to right: standing still with his arms
> down; walking with his left foot forward; walking with his right foot
> forward; waving with one arm raised high.
>
> Keep his face, hair, headband, scarf and clothes exactly as in the attached
> image. Drop the stage, the railing and the lights. Show only the man, head to
> shoes.
>
> Same camera distance and the same body height for all four figures, with
> their feet on one baseline. Clear empty space between the figures, so none of
> them touch or overlap. Plain flat off-white background, no gradient and no
> shadow on the floor. Nothing else in the scene. A dark outline around each
> figure. Front view.

## Ajit

Attach `Art/reference/ajit.png`.
Save as `Art/reference/ajit/strip-idle-walk-walk-busy.png`.

> Pixel art sprite strip of the same man as the attached image. Four full-body
> figures in one horizontal row, left to right: standing still with his arms
> down; walking with his left foot forward; walking with his right foot
> forward; lifting the racing helmet to put it on.
>
> Keep his face, grey hair and beard, white race suit and red boots exactly as
> in the attached image.
>
> Same camera distance and the same body height for all four figures, with
> their feet on one baseline. Clear empty space between the figures, so none of
> them touch or overlap. Plain flat off-white background, no gradient and no
> shadow on the floor. Nothing else in the scene. A dark outline around each
> figure. Front view.

## Rajni

Attach `Art/reference/rajni.png`.
Save as `Art/reference/rajni/strip-idle-walk-walk-alert.png`.

> Pixel art sprite strip of the same man as the attached image. Four full-body
> figures in one horizontal row, left to right: standing still with his arms
> down; walking with his left foot forward; walking with his right foot
> forward; flipping a coin from one hand, chin lifted.
>
> Keep his face, sunglasses, hair and tan suit exactly as in the attached
> image. The attached image stops at his chest. Show him head to shoes, in the
> same suit.
>
> Same camera distance and the same body height for all four figures, with
> their feet on one baseline. Clear empty space between the figures, so none of
> them touch or overlap. Plain flat off-white background, no gradient and no
> shadow on the floor. Nothing else in the scene. A dark outline around each
> figure. Front view.

## If a strip comes back wrong

- Figures touching: the importer counts the wrong number and stops with a
  message. Ask again for more space between them.
- One figure taller than the rest: the importer scales the whole strip by its
  tallest figure, so a tall pose shrinks the others. Ask again for one body
  height.
- Scenery kept: ask again with the scenery named. Anything touching a figure
  survives the background cut, because the cut floods in from the border and
  stops at the figure's outline.
