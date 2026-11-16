#!/usr/bin/env python3
"""Calisthenics challenges in the flyout, about once an hour (random, 45-75 min
apart) between 10:00 and 22:00. A systemd user timer runs `Workout.py tick`
every few minutes; it decides whether one is due.

Waits while: a call / recording uses the mic, the screen is shared, a focus
session runs, the screen is locked. Shows on top of games.

The flyout stays until answered:
  Done      logged; 2 clean completions in a row raise the target
  Too hard  logged; the target goes down a notch
  Skip      logged, no change
  Later     asks again in 10 minutes
Push, pull, legs and core rotate so the same muscles aren't hit twice in a row.
At 22:00 a summary (totals, streak = days with 4+ done).

  Workout.py tick                   (timer) show a challenge if one is due
  Workout.py now                    a challenge right away
  Workout.py done|hard|skip|later ID   flyout buttons
  Workout.py stats                  progress, targets, what to progress to next
  Workout.py today                  JSON for the quick settings tile
  Workout.py summary                today's summary as a flyout
  Workout.py --selftest

State: ~/.local/state/workout/ (state.json, log.jsonl).
"""
import datetime as dt
import json
import os
import random
import subprocess
import sys
import time

STATE_DIR = os.path.expanduser("~/.local/state/workout")
STATE = f"{STATE_DIR}/state.json"
LOG = f"{STATE_DIR}/log.jsonl"
RUNTIME = os.environ.get("XDG_RUNTIME_DIR", "/tmp")
SCRIPTS = os.path.dirname(os.path.realpath(__file__))
SELF = os.path.realpath(__file__)

HOURS = (10, 22)               # active from 10:00 until 22:00
GAP = (45 * 60, 75 * 60)       # seconds between challenges
SNOOZE = 10 * 60
STREAK_MIN = 4                 # done per day to keep the streak
ORDER = ["push", "pull", "legs", "core"]

# id: (name, group, unit, start, step, graduate_at, next_id, cue)
# unit "reps", "reps/side" or "s"; start ~70% of an advanced max; at
# graduate_at the stats suggest moving on to next_id
EXERCISES = {
    "pushup":      ("Push-ups", "push", "reps", 30, 2, 50, "diamond", "Body in one line, chest to the floor, elbows ~45°."),
    "diamond":     ("Diamond push-ups", "push", "reps", 20, 2, 35, "archer_pu", "Hands together under the chest, elbows brush the ribs."),
    "archer_pu":   ("Archer push-ups", "push", "reps/side", 8, 1, 15, "pseudo_pl", "Shift onto one arm, the other stays straight out to the side."),
    "pseudo_pl":   ("Pseudo-planche push-ups", "push", "reps", 10, 1, 20, None, "Hands by the hips, fingers out, lean forward past the hands."),
    "decline_pu":  ("Decline push-ups", "push", "reps", 20, 2, 35, "archer_pu", "Feet on a chair, slow down, explode up."),
    "dips":        ("Dips", "push", "reps", 15, 1, 25, None, "Shoulders down, go to 90° at the elbow, lock out at the top."),
    "pike_pu":     ("Pike push-ups", "push", "reps", 15, 1, 25, "wall_hspu", "Hips high, head towards the floor in front of the hands."),
    "wall_hspu":   ("Wall handstand push-ups", "push", "reps", 5, 1, 12, None, "Kick up to the wall, lower the head to a triangle with the hands."),
    "pullup":      ("Pull-ups", "pull", "reps", 12, 1, 20, "archer_pull", "Dead hang start, chin over the bar, no kipping."),
    "chinup":      ("Chin-ups", "pull", "reps", 12, 1, 20, "lsit_pull", "Palms facing you, chest to the bar."),
    "wide_pull":   ("Wide pull-ups", "pull", "reps", 9, 1, 15, None, "Hands wider than shoulders, pull the elbows down and back."),
    "commando":    ("Commando pull-ups", "pull", "reps/side", 5, 1, 10, None, "Hands close, bar along the body, alternate the head side."),
    "lsit_pull":   ("L-sit pull-ups", "pull", "reps", 6, 1, 12, None, "Legs straight out in front the whole set."),
    "neg_pull":    ("Slow negative pull-ups (5 s down)", "pull", "reps", 6, 1, 10, "archer_pull", "Jump to the top, lower for a full 5 seconds."),
    "dead_hang":   ("Dead hang", "pull", "s", 60, 5, 120, None, "Active shoulders, relaxed grip, breathe."),
    "archer_pull": ("Archer pull-ups", "pull", "reps/side", 4, 1, 8, None, "Pull to one hand, the other arm straightens along the bar."),
    "squat":       ("Squats", "legs", "reps", 50, 3, 80, "jump_squat", "Below parallel, knees out, heels down."),
    "jump_squat":  ("Jump squats", "legs", "reps", 20, 2, 35, None, "Land soft and go straight into the next rep."),
    "bulgarian":   ("Bulgarian split squats", "legs", "reps/side", 12, 1, 20, "pistol", "Back foot on a chair, front knee over the toes, upright torso."),
    "pistol":      ("Pistol squats", "legs", "reps/side", 6, 1, 12, None, "Hold a door frame if needed at first; heel down."),
    "wall_sit":    ("Wall sit", "legs", "s", 90, 10, 180, None, "Thighs parallel, back flat on the wall."),
    "calf":        ("Single-leg calf raises", "legs", "reps/side", 20, 2, 35, None, "On a step, full stretch at the bottom, pause at the top."),
    "handstand":   ("Wall handstand hold", "core", "s", 60, 5, 120, None, "Chest to the wall, push the floor away, body tight."),
    "lsit":        ("L-sit (chairs or dip bars)", "core", "s", 20, 3, 45, None, "Straight legs, shoulders pushed down."),
    "hollow":      ("Hollow body hold", "core", "s", 60, 5, 120, None, "Lower back glued to the floor, arms overhead."),
    "leg_raise":   ("Hanging leg raises", "core", "reps", 12, 1, 20, "dragon_flag", "No swinging, toes to the bar if you can."),
    "dragon_flag": ("Dragon flag negatives", "core", "reps", 5, 1, 10, None, "Hold behind your head, lower the straight body slowly."),
    "planche_lean": ("Planche lean hold", "core", "s", 30, 3, 60, None, "Straight arms, lean the shoulders past the hands."),
}


# ---- state -------------------------------------------------------------
def load():
    try:
        return json.load(open(STATE))
    except (OSError, ValueError):
        return {"targets": {}, "clean": {}, "next_due": 0, "last_group": None, "pending": None, "summary_day": None}


def save(st):
    os.makedirs(STATE_DIR, exist_ok=True)
    with open(STATE + ".tmp", "w") as f:
        json.dump(st, f, indent=1)
    os.replace(STATE + ".tmp", STATE)


def log(entry):
    os.makedirs(STATE_DIR, exist_ok=True)
    with open(LOG, "a") as f:
        f.write(json.dumps(entry) + "\n")


def entries(day=None):
    try:
        lines = open(LOG).read().splitlines()
    except OSError:
        return []
    out = [json.loads(l) for l in lines if l.strip()]
    return [e for e in out if day is None or e["day"] == day]


def target(st, ex):
    return st["targets"].get(ex, EXERCISES[ex][3])


def amount(st, ex):
    name, _g, unit, *_ = EXERCISES[ex]
    t = target(st, ex)
    return f"{t} s" if unit == "s" else f"{t} {'per side' if unit == 'reps/side' else 'reps'}"


# ---- progression (pure, tested) -----------------------------------------
def progress(targets, clean, ex, result):
    """New (target, clean streak) after a result: 2 clean "done" in a row
    raise the target by one step, "hard" lowers it, "skip" changes nothing."""
    start, step = EXERCISES[ex][3], EXERCISES[ex][4]
    t, c = targets.get(ex, start), clean.get(ex, 0)
    if result == "done":
        c += 1
        if c >= 2:
            t, c = t + step, 0
    elif result == "hard":
        t, c = max(step, t - step), 0
    return t, c


def pick(st, rng=random):
    """An exercise from the next muscle group in the rotation, preferring
    ones not done recently."""
    last = st.get("last_group")
    group = ORDER[(ORDER.index(last) + 1) % len(ORDER)] if last in ORDER else rng.choice(ORDER)
    pool = [k for k, v in EXERCISES.items() if v[1] == group]
    recent = [e["ex"] for e in entries()[-12:]]
    fresh = [k for k in pool if k not in recent] or pool
    return rng.choice(fresh)


# ---- conditions --------------------------------------------------------
def busy():
    """A reason to wait, or None."""
    if os.path.exists(f"{RUNTIME}/focus-active"):
        return "focus"
    if os.path.exists(f"{RUNTIME}/qs-lock-active"):
        return "locked"
    try:
        out = subprocess.run(["pactl", "-f", "json", "list", "source-outputs"], capture_output=True, text=True, timeout=5).stdout
        sources = {s["index"]: s["name"] for s in json.loads(subprocess.run(
            ["pactl", "-f", "json", "list", "sources"], capture_output=True, text=True, timeout=5).stdout)}
        for so in json.loads(out or "[]"):
            if not sources.get(so.get("source"), "").endswith(".monitor"):
                return "mic in use"
        dump = subprocess.run(["pw-dump"], capture_output=True, text=True, timeout=5).stdout
        if '"node.name": "xdph' in dump:
            return "screen share"
    except (OSError, ValueError, subprocess.TimeoutExpired):
        pass
    return None


# ---- flyouts -----------------------------------------------------------
def quip(kind):
    return subprocess.run([f"{SCRIPTS}/Pack.sh", "quip", kind], capture_output=True, text=True).stdout.strip()


def flyout(title, sub, extra=None):
    subprocess.run(["qs", "ipc", "call", "osd", "rich", "workout", title, sub, json.dumps(extra or {})],
                   capture_output=True)


def show(st, ex):
    name, group, unit, *_rest, cue = EXERCISES[ex]
    st["pending"] = ex
    save(st)
    btn = lambda label, glyph, act: {"label": label, "glyph": glyph, "cmd": [SELF, act, ex]}
    line = quip("workout")
    flyout(f"{name}: {amount(st, ex)}", (line + " · " if line else "") + cue,
           {"sticky": True, "actions": [btn("Done", 0xF012C, "done"), btn("Too hard", 0xF072E, "hard"),
                                         btn("Skip", 0xF0156, "skip"), btn("Later", 0xF0150, "later")]})


def today():
    return dt.date.today().isoformat()


def streak():
    days = {}
    for e in entries():
        if e["result"] == "done":
            days[e["day"]] = days.get(e["day"], 0) + 1
    n, d = 0, dt.date.today()
    if days.get(d.isoformat(), 0) < STREAK_MIN:      # today still counts as open
        d -= dt.timedelta(days=1)
    while days.get(d.isoformat(), 0) >= STREAK_MIN:
        n, d = n + 1, d - dt.timedelta(days=1)
    return n


def answer(st, result, ex):
    if ex not in EXERCISES:
        return
    if result == "later":
        st["pending"], st["next_due"] = ex, time.time() + SNOOZE
        save(st)
        return
    t_before = target(st, ex)
    t, c = progress(st["targets"], st["clean"], ex, result)
    st["targets"][ex], st["clean"][ex] = t, c
    st["pending"] = None
    st["last_group"] = EXERCISES[ex][1]
    st["next_due"] = time.time() + random.randint(*GAP)
    save(st)
    log({"t": int(time.time()), "day": today(), "ex": ex, "amount": t_before, "result": result})
    done_today = sum(1 for e in entries(today()) if e["result"] == "done")
    if result == "done":
        up = f" · next time {t}" if t > t_before else ""
        flyout(quip("workoutDone") or "Nice work!", f"{EXERCISES[ex][0]} done · {done_today} today · streak {streak()} d{up}")
    elif result == "hard":
        flyout("Noted, easing off", f"{EXERCISES[ex][0]}: {amount(st, ex)} next time")


def summary_text():
    done = [e for e in entries(today()) if e["result"] == "done"]
    if not done:
        return "No challenges done today", "Tomorrow's a new day."
    totals = {}
    for e in done:
        totals[e["ex"]] = totals.get(e["ex"], 0) + e["amount"]
    parts = []
    for ex, n in totals.items():
        unit = EXERCISES[ex][2]
        parts.append(f"{EXERCISES[ex][0]} {n}{' s' if unit == 's' else ''}")
    return f"Today: {len(done)} challenges · streak {streak()} d", ", ".join(parts)


def tick():
    st, now = load(), dt.datetime.now()
    if now.hour >= HOURS[1] and st.get("summary_day") != today():
        st["summary_day"] = today()
        save(st)
        flyout(*summary_text())
        return
    if not HOURS[0] <= now.hour < HOURS[1]:
        return
    if not st.get("next_due"):                         # first run: first one within the hour
        st["next_due"] = time.time() + random.randint(5 * 60, 30 * 60)
        save(st)
        return
    if time.time() < st["next_due"] or busy():
        return
    show(st, st.get("pending") or pick(st))


def stats():
    st = load()
    rows, all_e = [], entries()
    for ex, (name, group, unit, start, step, grad, nxt, _cue) in EXERCISES.items():
        mine = [e for e in all_e if e["ex"] == ex and e["result"] == "done"]
        total = sum(e["amount"] for e in mine)
        t = target(st, ex)
        hint = ""
        if t >= grad and nxt:
            hint = f"ready: move on to {EXERCISES[nxt][0]}"
        elif t >= grad:
            hint = "mastered at this level: add a weighted backpack or slow tempo"
        rows.append((group, name, amount(st, ex), len(mine), total, unit, hint))
    print(f"\033[1mStreak {streak()} days · {sum(1 for e in all_e if e['result'] == 'done')} challenges done\033[0m\n")
    for group in ORDER:
        print(f"\033[1;34m{group.upper()}\033[0m")
        for g, name, amt, n, total, unit, hint in rows:
            if g == group:
                tot = f"{total} s" if unit == "s" else f"{total}"
                print(f"  {name:36} target {amt:16} done {n:3}× total {tot:>7}  \033[33m{hint}\033[0m")
        print()


def selftest():
    t, c = progress({}, {}, "pushup", "done")
    assert (t, c) == (30, 1)
    t, c = progress({"pushup": 30}, {"pushup": 1}, "pushup", "done")
    assert (t, c) == (32, 0)
    t, c = progress({"pushup": 32}, {"pushup": 1}, "pushup", "hard")
    assert (t, c) == (30, 0)
    t, c = progress({"pushup": 32}, {"pushup": 1}, "pushup", "skip")
    assert (t, c) == (32, 1)
    st = {"targets": {}, "clean": {}, "last_group": "push"}
    assert EXERCISES[pick(st, random.Random(1))][1] == "pull"
    st["last_group"] = "core"
    assert EXERCISES[pick(st, random.Random(1))][1] == "push"
    print("selftest ok")


def main():
    cmd = sys.argv[1] if len(sys.argv) > 1 else "tick"
    if cmd == "--selftest":
        selftest()
    elif cmd == "tick":
        tick()
    elif cmd == "now":
        st = load()
        show(st, st.get("pending") or pick(st))
    elif cmd in ("done", "hard", "skip", "later") and len(sys.argv) > 2:
        answer(load(), cmd, sys.argv[2])
    elif cmd == "stats":
        stats()
    elif cmd == "summary":
        flyout(*summary_text())
    elif cmd == "today":
        print(json.dumps({"done": sum(1 for e in entries(today()) if e["result"] == "done"), "streak": streak()}))
    else:
        print(__doc__)


if __name__ == "__main__":
    main()
