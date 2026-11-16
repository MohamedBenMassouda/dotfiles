# CLAUDE.md

Scope: **`Workout.py` only**. The other scripts in this folder follow `~/dotfiles/CLAUDE.md`.
Where the two disagree (comments, mostly), this file wins for `Workout.py`.

Workout is a calisthenics trainer for one user (90 kg, advanced, training for muscle size plus
two skills: free-standing handstand and one-arm pull-up). It is a single stdlib Python 3 file.
A systemd user timer runs `Workout.py tick` every 3 minutes. About once an hour between 10:00
and 22:00, the tick picks a challenge (a hard set counted against weekly per-group caps, skill
practice, or a weekly boss challenge) and shows it in the Quickshell flyout. The user answers
with flyout buttons, which call `Workout.py` back with the answer. Durable state is two files in
`~/.local/state/workout/`: `state.json` (targets, ladder rungs, pending challenge, schedule) and
`log.jsonl` (append-only event log). The UI, sounds and lines belong to other parts of the
dotfiles. This script only shells out to them.

Layout: `.config/hypr/scripts/Workout.py` (all logic), `.config/systemd/user/workout.service` +
`workout.timer` (the 3-minute tick), the Training tile in `.config/quickshell/panels/ControlCenter.qml`
(calls `now`, `session`, `test-window`, `stats`, and parses `today`), the `workout` flyout kind in
`.config/quickshell/Osd.qml`, the focus flag written by `.config/quickshell/Globals.qml`, and the
quips `workout`, `workoutDone`, `levelUp`, `boss` in `.config/quickshell/packs/spiderman/pack.json`
(read through `Pack.sh quip`). No package manager, no dependencies, no build step.
There is one branch, `main`, and no deployment: the repo is stowed into `~`, so a saved edit is live
and the next timer run uses it.

## Commands

From `~/dotfiles/.config/hypr/scripts`:

| Command                                                   | Does                                                          |
| --------------------------------------------------------- | ------------------------------------------------------------- |
| `python3 Workout.py --selftest`                           | the gate. Run it before declaring work done                   |
| `HOME=<scratch> PATH=<scratch>/bin:$PATH python3 Workout.py now` | one flow against throwaway state; `<scratch>/bin/qs` and `Pack.sh` stubs keep flyouts off the real screen. Drive `done`, `rir`, `skip`, `later`, `session`, `test` the same way |
| `systemctl --user list-timers workout.timer`              | is the tick scheduled                                         |
| `journalctl --user -u workout.service -n 50`              | output and tracebacks of recent ticks                         |
| `python3 Workout.py stats`                                | targets, ladder rungs, weekly caps, last max test             |
| `python3 Workout.py now`                                  | manual smoke rig. Shows a **real** sticky card on the user's screen and writes **real** state. Never in a test, and ask first |

There is no CI. Nothing runs the self-test for you: run it yourself after every change.

Commits go straight to `main` as small conventional commits (`feat(training): …`,
`fix(training): …`), authored by the user, with no AI co-author or attribution. Push only when asked.
There is no PR template.

## Code style: the contract

Non-negotiable, and they apply to every language in this repo. Treat a violation as a bug.

**1. No magic values.** Every literal, number or string, is a named constant whose name
explains it. No exceptions for "obvious" values. Retry limits, thresholds, page sizes and
timeouts are named fields on the type that owns them. Enum-like sets are real enums, never a
bare string compared inline.
Constants that already follow this: `HOURS`, `GAP`, `SNOOZE`, `STREAK_MIN`, `CAPS`,
`SESSION_USES`, `SKILL_SHARE`, `RETEST_DAYS`.

**2. No comments.** Names carry the meaning. If a block needs a comment, it needs a better
name or its own function. This covers doc-comment blocks and banner separators
(`// ===== SECTION =====`) too: a file that needs section headers needs splitting.
`Workout.py` violates this today: the module docstring, the `# ---- state ----` banners, the
inline comments, and the comments inside `selftest()`. Treat them as cleanup, not precedent.
Do not add more, and do not cite an existing comment as precedent. Where a
comment records a real constraint (a vendor quirk, or a production incident the obvious change
would bring back), move it into this file or into `~/dotfiles/CLAUDE.md` and delete it from the
source. Never leave commented-out code. Git remembers it.

**3. Self-explanatory names.** No abbreviations: `DrainNextPage`, not `DrainNext`. When two
kinds of id are in scope, disambiguate them (`parentId` vs `childId`, `jobRunId` vs
`dataRunId`). Loop variables get real names. Vendor and domain acronyms that are a proper
name stay (RIR = reps in reserve, JSON, IPC, QML, HSPU, OAP).
Python conventions: `snake_case` functions and variables, `UPPER_SNAKE` module constants, one file.
The existing code abbreviates heavily (`st`, `ex`, `e`, `lid`, `rir`-as-variable, `EX`). Rename
when you touch a function rather than mixing both styles inside one function.

**4. Blank line before and after control-flow keywords:** `if`, `else`, `for`, `foreach`,
`while`, `return`, `throw`, `switch`, `try`. A block owns its braces, so **never** put a blank
line directly after an opening brace or a `case` label, and **never** put one directly before
a closing brace.

No function in `Workout.py` meets rules 1–4 yet. This is `streak()` in the target shape
(`SET_ENTRY`, `RESULT_DONE` and `ONE_DAY` are the named constants it would introduce). In Python
the line ending in `:` is the opening brace, so no blank line follows it:

```python
def count_streak_days(log_entries):
    completed_per_day = {}

    for entry in log_entries:
        if entry.get("type") == SET_ENTRY and entry.get("result") == RESULT_DONE:
            completed_per_day[entry["day"]] = completed_per_day.get(entry["day"], 0) + 1

    streak_days = 0
    checked_day = dt.date.today()

    if completed_per_day.get(checked_day.isoformat(), 0) < STREAK_MIN:
        checked_day -= ONE_DAY

    while completed_per_day.get(checked_day.isoformat(), 0) >= STREAK_MIN:
        streak_days += 1
        checked_day -= ONE_DAY

    return streak_days
```

Nothing enforces rule 4 mechanically. Follow it by hand, everywhere in the repo.

**5. DRY.** Shared behaviour goes in the shared scripts in `.config/hypr/scripts`. Pure helpers
live inside `Workout.py` (`load`, `save`, `log`, `entries`, `target`, `amount`, `current`).
Anything touching the desktop goes through the existing shell-outs: `flyout()` (`qs ipc call
osd rich`), `quip()` (`Pack.sh quip`) and `busy()` (pactl, pw-dump, runtime flag files).
Pack-specific text stays in `packs/<name>/pack.json`. Check those helpers before writing a new one.

## Challenge scheduling and progression contract

Everything non-obvious lives in four functions and three tables:

- **`tick()`** decides, in this order, and returns after the first match: the 20:00 protein
  check-in, the 23:30 bedtime reminder, the 22:00 summary (each once a day via `st["days"]`
  stamps), then outside 10:00–22:00 nothing, the retest reminder (no test or older than
  `RETEST_DAYS`), the first-run delay, then "not due yet or `busy()`", then show the pending
  challenge or `pick()` a new one.
- **`pick()`** chooses between `hard`, `skill` and `boss`. Groups logged as trained today (a
  `session` entry) are skipped, and so is any group at its weekly cap (`cap_used()` counts done
  hard sets plus session allowances from `SESSION_USES`). The chance of skill practice is
  `SKILL_SHARE` (training day vs rest day). A boss comes at most once a week, rest days, after 15:00.
- **`progress()`** turns a reps-left answer (3, 1 or 0) into a new target: 3+ raises it by
  the exercise's step, three 1–2 answers in a row raise it, failure keeps it and resets the run.
  Reaching the exercise's top moves the ladder to the next rung.
- **`test()`** sets each ladder to the hardest tested movement with a real result and its
  target to a share of the max (strength vs skill share).
- **`EX`** holds `id: (name, unit, start, step, top of rung, cue)`. **`LADDERS`** (group →
  ladder id → ids, easy to hard), **`SKILLS`** (skill → ids) and **`BOSSES`**/**`TEST`** reference
  those ids. A new exercise goes in `EX` and in exactly one ladder. Add it to `TEST` only if the
  max test should measure it.

### Durable state and re-runs

**Every step is a resume.** Each CLI call is a fresh process that reads `state.json`, acts and
writes it back. Ticks are re-triggered by the timer every 3 minutes, and flyout buttons can be
clicked more than once or long after the card appeared. Every handler must be idempotent and
safe to re-run after a kill at any step boundary. Anything that must survive the step is
persisted before you return.

**Every write to persisted state is an upsert.** A handler killed after its write but before
its state transition runs again from the top:

- Use indexer or set semantics (`map[key] = value`), not `Add`, which throws or duplicates on
  a re-run. When the first value must win on purpose, say so with `TryAdd`. Never wrap `Add`
  in a `ContainsKey` guard.
- Check for existing children before fanning out, unless the creation call is itself
  idempotent.
- Never append to a list stored in persisted state (read, append, write). Derive the list from
  a count, or use a set.
- Never persist a running total accumulated across steps. Store absolute values.
  Reference implementation: `cap_used()` and `streak()` derive totals from `log.jsonl` every
  time, and `targets` stores absolute values. `log.jsonl` is the one deliberate append-only
  store: it is an event log, nothing reads it back as a list to extend.
  Known violation: `test()` appends to `st["tests"]` (move it to the event log).

### Runtime-only contracts

- **Exercise ids are data.** They are stored in `state.json` (`targets`, `clean`, `pending`) and
  in every `log.jsonl` entry. Renaming one orphans its history; `load()` only drops a `pending`
  whose id no longer exists. To rename, migrate both files.
- **The button argv is an interface.** Flyout actions call `Workout.py done|skip|later <id>`
  and `Workout.py rir <id> 3|1|0`. The QML tile calls `now`, `session upper|legs|full`,
  `test-window`, `stats` and `today`.
- **`today` output is parsed by QML.** The keys `done`, `streak`, `skills` and `trained` are read
  in `ControlCenter.qml`. A renamed key fails silently in the tile.
- **The flyout kind `workout`** must exist in `Osd.qml` `kinds`, or the card gets a bell icon.
- **The pack quip names** `workout`, `workoutDone`, `levelUp` and `boss` must exist in
  `pack.json`. A missing one falls back to plain text.
- **Flag files:** `$XDG_RUNTIME_DIR/focus-active` (written by `Globals.qml`) and
  `$XDG_RUNTIME_DIR/qs-lock-active` (written by the lock screen) make `busy()` wait.
- **Log entry types:** `set`, `session`, `test`. Counting code filters on `type`, and entries
  without it are ignored, so older logs stay harmless.

### Results, retries, errors

There are no retries. A failed shell-out (`qs`, `pactl`, `pw-dump`, `Pack.sh`) is swallowed:
`busy()` treats errors as "not busy", and a lost flyout comes back because the pending challenge
is shown again on a later tick. Subprocess calls use a 5-second timeout. A crash in `tick` only
skips that tick (see `journalctl --user -u workout.service`).

## Testing

stdlib only: `selftest()` inside `Workout.py`, run with `python3 Workout.py --selftest`.

- **No network, no secret store, no real vendor API from the test suite.** Fake HTTP at the
  transport layer (not needed here: there is no HTTP; fake the shell-outs with `PATH` stubs for
  `qs` and `pactl`) so production code needs no test hooks.
- Fixtures live in `selftest()` as inline state dicts and log lists. Doubles and spies live in a
  scratch `bin/` on `PATH`. Reuse them before writing new ones.
- Test display names are sentences about behaviour, not restatements of the method name:
  `assert target(state, "c2b") == 12, "three 1-2-left answers in a row raise the target"`,
  with a matching `progress_raises_target_after_three_steady_sets` name.
- New tests go under `selftest()` until it outgrows the file, then `Workout_test.py` next to it.
  `selftest()` currently explains its asserts in comments: move those into assert messages,
  and do not add to them.
- Manual rigs that touch real secrets or APIs are not tests. Keep them out of CI and never
  let anything in CI depend on them.
- To test the scheduling end to end, drive it from the CLI with `HOME=<scratch>`: each
  invocation is a new process that rebuilds from `state.json`, which is exactly a kill/resume.
  Check the state and log files, not stdout: `flyout()` captures the output of the `qs` stub.

## Gotchas

- `busy()` must ignore `.monitor` sources: the bar's cava visualiser always records one.
  Discord and other WebRTC apps hold the mic during a call, so challenges correctly wait.
- An unanswered sticky card is sent again on every tick (every 3 minutes), because `show()`
  doesn't move `next_due`. It replaces the same card, but notice it before "fixing" the timer.
- `finish()` does not check that the answered id is the pending one, so a double click on a
  reps-left button logs the set twice. Guard on `st["pending"]` when you touch it.
- `pick()` reads the clock (boss after 15:00, today's sessions) and `random`. Pass a seeded
  `random.Random` in tests, and expect the boss branch to fire depending on the time of day.
- The first version stored `pending` as a bare id string. `load()` normalises anything that is
  not a 4-item list to `None`. Keep that guard.
- `Pack.sh quip` reads `pack.json` on every call, so new quips work at once. The QML side only
  re-reads packs after a shell restart.
- `test()` reads answers from stdin. Run it in a terminal (`test-window` opens kitty); piped
  input works for tests.
- zsh is the login shell: unquoted `$var` is not word-split, and `pkill -f` matches its own
  command line. Use exact PIDs.
- Nothing is gated: no CI, no lint, no type check.

## Working style

- Verify a fix by breaking it: revert the change and confirm the test fails. A test that
  passes both ways proves nothing.
- Before you report a regression or a pre-existing bug, check `git show HEAD:<path>` to tell
  which one it is.
- Fix the root cause, not the caller that reported it. One fix in the shared helper is a
  smaller diff than a guard in every caller, and patching one caller leaves the others broken.
- When a shared change breaks tests, fix the tests to match the new truth. Do not weaken
  assertions to make them pass.
- Report what actually happened, including what was skipped and what still needs doing.
