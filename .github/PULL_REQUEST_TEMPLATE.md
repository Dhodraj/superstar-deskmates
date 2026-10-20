## What this changes

<!-- One or two sentences. -->

## How you know it works

<!-- Which checks you added or ran. For anything needing a cursor, which row
     of CHECKS.md you went through. -->

- [ ] `swift build` passes
- [ ] `swift run Checks` passes
- [ ] New behaviour has a check that fails without it

## If this adds a character

- [ ] Art imported with `scripts/import_reference.py`
- [ ] Every mood the job reports has a pose
- [ ] The reference images are in `Art/reference/<name>/`

## If this adds a job

- [ ] Reads only this machine. No network, no analytics, no permission prompt
- [ ] Reports changes, not the same mood every poll
- [ ] The outside world is passed in, so a check can drive it
