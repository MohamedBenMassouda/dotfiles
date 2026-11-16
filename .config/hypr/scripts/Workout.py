#!/usr/bin/env python3
"""Calisthenics training through the day: muscle size first, plus two skills
(handstand, one-arm pull-up). A systemd user timer runs `Workout.py tick`
every 3 minutes; about once an hour (random, 45-75 min apart, 10:00-22:00) a
challenge appears in the flyout. Waits during calls, screen sharing, focus
sessions and while locked; shows on top of games.

Each challenge is either
  a hard set     close to failure, counts toward the weekly cap of its group
                 (push 10, pull 10, legs 6, core 6 hard sets a week), or
  skill practice handstand / one-arm pull-up work, kept fresh, never to failure.
On days you log a session (quick settings > Training > Trained today) the
challenges skip the trained groups and lean towards skill practice; rest days
lean towards hard sets. About once a week on a rest day: a boss challenge.

Exercises sit on ladders of harder movements (explosive, one-sided, tempo,
drop sets) instead of more weight: when a target reaches the top of its rung
the ladder moves on (e.g. chest-to-bar -> explosive -> archer -> typewriter).

Answering: Done / Skip / Later, then "3+ left" (target up), "1-2 left"
(three in a row: up), "Failure" (stays). Max test (terminal, ~15 min) sets the
targets to ~70% of your real maxes; a reminder comes every 6 weeks.
Also: 20:00 protein check-in (90 kg: ~145-180 g), 23:30 bedtime reminder,
22:00 summary (sets per group, weekly caps, skills, streak = days with 4+ done).

  Workout.py tick | now | stats | test | today | summary | --selftest
  Workout.py done|skip|later ID       first buttons
  Workout.py rir ID 3|1|0             "reps left" buttons
  Workout.py session upper|legs|full  log a training session today
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

HOURS = (10, 22)                     # challenges from 10:00 until 22:00
GAP = (45 * 60, 75 * 60)             # seconds between challenges
SNOOZE = 10 * 60
STREAK_MIN = 4                       # challenges a day to keep the streak
CAPS = {"push": 10, "pull": 10, "legs": 6, "core": 6}       # hard sets a week from challenges
SESSION_USES = {"upper": {"push": 6, "pull": 6}, "legs": {"legs": 6},
                "full": {"push": 4, "pull": 4, "legs": 4, "core": 4}}
SESSION_GROUPS = {"upper": {"push", "pull"}, "legs": {"legs"}, "full": {"push", "pull", "legs", "core"}}
SKILL_SHARE = {"training": 0.7, "rest": 0.3}               # chance of skill practice
PROTEIN = (20, 0, "Protein check: ~145-180 g today?", "At 90 kg that's 1.6-2 g/kg. Short? Shake, eggs, Greek yoghurt.")
BEDTIME = (23, 30, "Bedtime soon", "Muscle grows while you sleep: aim for 8 hours.")
RETEST_DAYS = 42
ORDER = ["push", "pull", "legs", "core"]

# exercise id: (name, unit, start, step, top of rung, cue); unit "reps", "side" (reps per side), "s", "tries"
EX = {
    # push
    "clap_pu":     ("Clap push-ups", "reps", 12, 1, 20, "Explode off the floor, land soft with bent elbows."),
    "archer_pu":   ("Archer push-ups", "side", 8, 1, 15, "Shift onto one arm, the other stays straight out."),
    "pseudo_pl":   ("Pseudo-planche push-ups", "reps", 10, 1, 20, "Hands by the hips, lean well past the hands."),
    "oa_pu":       ("One-arm push-ups", "side", 5, 1, 12, "Feet wide, hips square, chest to the fist."),
    "oa_pu_tempo": ("One-arm push-ups, 4 s down", "side", 4, 1, 10, "Four full seconds down, pause, drive up."),
    "dips":        ("Dips", "reps", 15, 1, 25, "Shoulders down, 90° at the elbow, lock out."),
    "dips_tempo":  ("Tempo dips (4 s down, 2 s pause)", "reps", 8, 1, 15, "Slow down, pause at the bottom, drive up."),
    "pike_pu":     ("Elevated pike push-ups", "reps", 12, 1, 20, "Feet on a chair, hips high, head to the floor."),
    "wall_hspu":   ("Wall handstand push-ups", "reps", 6, 1, 12, "Head to a triangle with the hands, full lockout."),
    "deficit_hspu": ("Deficit wall handstand push-ups", "reps", 4, 1, 10, "Hands on books, lower the head below hand level."),
    "drop_push":   ("Drop set: archer → diamond → regular push-ups", "reps", 6, 1, 12, "Reps per part, no rest between."),
    # pull
    "c2b":         ("Chest-to-bar pull-ups", "reps", 10, 1, 15, "Pull the chest to the bar, elbows back."),
    "explosive":   ("Explosive high pull-ups", "reps", 8, 1, 12, "Pull as high as you can, hands leave the bar if you can."),
    "archer_pull": ("Archer pull-ups", "side", 5, 1, 8, "Pull to one hand, the other arm straight along the bar."),
    "typewriter":  ("Typewriter pull-ups", "side", 4, 1, 8, "Up, slide side to side at the top, down."),
    "muscle_up":   ("Muscle-ups", "reps", 5, 1, 10, "False grip if you like, clean transition, no kipping."),
    "mu_tempo":    ("Slow muscle-ups (3 s down)", "reps", 3, 1, 6, "Control the way down through the transition."),
    "chin_tempo":  ("Chin-ups, 4 s down", "reps", 8, 1, 12, "Chest to the bar, four seconds down."),
    "lsit_chin":   ("L-sit chin-ups", "reps", 6, 1, 12, "Legs straight out the whole set."),
    "drop_pull":   ("Drop set: archer → wide → regular pull-ups", "reps", 4, 1, 8, "Reps per part, no rest between."),
    # legs
    "jump_squat":  ("Jump squats", "reps", 20, 2, 35, "Land soft, straight into the next rep."),
    "shrimp":      ("Shrimp squats", "side", 6, 1, 12, "Hold the back foot, knee to the floor."),
    "pistol":      ("Pistol squats", "side", 8, 1, 15, "Heel down, arms forward, no bounce."),
    "pistol_tempo": ("Pistol squats, 4 s down", "side", 5, 1, 10, "Four seconds down, pause, up."),
    "bulgarian":   ("Bulgarian split squats, 3 s down", "side", 10, 1, 15, "Back foot on a chair, upright torso."),
    "jump_lunge":  ("Jumping lunges", "reps", 20, 2, 30, "Switch legs in the air, soft landing."),
    "calf":        ("Single-leg calf raises", "side", 20, 2, 35, "Full stretch, pause at the top."),
    # core
    "leg_raise":   ("Hanging leg raises", "reps", 12, 1, 20, "No swinging."),
    "t2b":         ("Toes-to-bar", "reps", 10, 1, 15, "Toes touch the bar, controlled down."),
    "dragon":      ("Dragon flag negatives", "reps", 5, 1, 10, "Straight body, lower slowly."),
    "hollow":      ("Hollow body hold", "s", 60, 5, 120, "Lower back glued to the floor."),
    "lsit":        ("L-sit", "s", 20, 3, 45, "Straight legs, shoulders pushed down."),
    "vsit":        ("V-sit attempts", "s", 5, 1, 15, "From the L-sit, lift the legs higher."),
    # skills (never to failure)
    "hs_wall":     ("Chest-to-wall handstand", "s", 60, 5, 90, "Belly to the wall, push the floor away, tight body."),
    "hs_toepull":  ("Toe-pull handstand holds", "tries", 6, 1, 10, "From the wall, pull the toes off and balance, 5-10 s each."),
    "hs_kickup":   ("Free kick-up attempts", "tries", 8, 1, 12, "Kick up away from the wall, find balance, bail safely."),
    "hs_free":     ("Free-standing handstand", "s", 10, 2, 60, "Best of 5 tries. Fingers do the balancing."),
    "oap_archer":  ("One-arm pull-up practice: archer pull-ups", "side", 3, 1, 6, "Two sets, stop 2 reps before failure."),
    "oap_type":    ("One-arm pull-up practice: typewriters", "side", 3, 1, 6, "Two sets, slow at the sides."),
    "oap_towel":   ("Towel-assisted one-arm pull-ups", "side", 3, 1, 6, "Other hand on a towel low down, help as little as you can."),
    "oap_neg":     ("One-arm pull-up negatives (5 s)", "side", 3, 1, 6, "Get to the top with both, lower on one arm for 5 s."),
    "oap":         ("One-arm pull-ups", "side", 1, 1, 5, "Dead hang, pull with one arm, other hand free."),
}
# ladders: hard sets per group, then the two skills; each ladder is easier -> harder
LADDERS = {
    "push": {"pushup": ["clap_pu", "archer_pu", "pseudo_pl", "oa_pu", "oa_pu_tempo"],
             "dip": ["dips", "dips_tempo"],
             "vertical": ["pike_pu", "wall_hspu", "deficit_hspu"],
             "drop_push": ["drop_push"]},
    "pull": {"pullup": ["c2b", "explosive", "archer_pull", "typewriter"],
             "muscleup": ["muscle_up", "mu_tempo"],
             "chin": ["chin_tempo", "lsit_chin"],
             "drop_pull": ["drop_pull"]},
    "legs": {"squat": ["jump_squat", "shrimp", "pistol", "pistol_tempo"],
             "split": ["bulgarian", "jump_lunge"],
             "calf": ["calf"]},
    "core": {"lever": ["leg_raise", "t2b", "dragon"],
             "hold": ["hollow", "lsit", "vsit"]},
}
SKILLS = {"handstand": ["hs_wall", "hs_toepull", "hs_kickup", "hs_free"],
          "one-arm pull-up": ["oap_archer", "oap_type", "oap_towel", "oap_neg", "oap"]}
BOSSES = [("muscle_up", "Max muscle-ups in one set"), ("oa_pu", "Max one-arm push-ups (each side)"),
          ("c2b", "Max chest-to-bar pull-ups"), ("pistol", "Max pistol squats (each side)")]
# max test: exercise ids asked for, in this order
TEST = ["clap_pu", "archer_pu", "oa_pu", "dips", "wall_hspu", "c2b", "archer_pull", "muscle_up",
        "pistol", "t2b", "lsit", "hs_wall", "hs_free"]


# ---- state ----------------------------------------------------------------
def load():
    try:
        st = json.load(open(STATE))
    except (OSError, ValueError):
        st = {}
    for k, v in {"targets": {}, "clean": {}, "rung": {}, "next_due": 0, "last_group": None,
                 "pending": None, "kind": None, "days": {}}.items():
        st.setdefault(k, v)
    p = st.get("pending")
    if not (isinstance(p, list) and len(p) == 4 and p[3] in EX):   # older format or removed exercise
        st["pending"] = None
    return st


def save(st):
    os.makedirs(STATE_DIR, exist_ok=True)
    with open(STATE + ".tmp", "w") as f:
        json.dump(st, f, indent=1)
    os.replace(STATE + ".tmp", STATE)


def log(entry):
    os.makedirs(STATE_DIR, exist_ok=True)
    entry = {"t": int(time.time()), "day": today(), **entry}
    with open(LOG, "a") as f:
        f.write(json.dumps(entry) + "\n")


def entries():
    try:
        return [json.loads(l) for l in open(LOG).read().splitlines() if l.strip()]
    except OSError:
        return []


def today():
    return dt.date.today().isoformat()


def week_start(day=None):
    d = dt.date.fromisoformat(day) if day else dt.date.today()
    return (d - dt.timedelta(days=d.weekday())).isoformat()


def target(st, ex):
    return st["targets"].get(ex, EX[ex][2])


def amount(st, ex):
    unit, t = EX[ex][1], target(st, ex)
    return {"s": f"{t} s", "side": f"{t} per side", "tries": f"{t} tries"}.get(unit, f"{t} reps")


def current(st, ladder_id, ladder):
    return ladder[min(st["rung"].get(ladder_id, 0), len(ladder) - 1)]


# ---- rules (pure, tested) -------------------------------------------------
def progress(st, ladder_id, ladder, ex, rir):
    """Apply a "reps left" answer: 3+ left raises the target, three times 1-2
    left in a row raises it too, failure keeps it. Reaching the top of the rung
    moves the ladder to the next exercise. Returns a level-up message or None."""
    step, top = EX[ex][3], EX[ex][4]
    t, c = target(st, ex), st["clean"].get(ex, 0)
    if rir >= 3:
        t, c = t + step, 0
    elif rir >= 1:
        c += 1
        if c >= 3:
            t, c = t + step, 0
    else:
        c = 0
    st["targets"][ex], st["clean"][ex] = t, c
    i = ladder.index(ex)
    if t >= top and i + 1 < len(ladder):
        st["rung"][ladder_id] = i + 1
        return f"Level up: {EX[ladder[i + 1]][0]} ({amount(st, ladder[i + 1])})"
    return None


def cap_used(log_entries, week):
    """Hard sets used per group this week: challenge sets plus logged sessions."""
    used = {g: 0 for g in CAPS}
    for e in log_entries:
        if week_start(e["day"]) != week:
            continue
        if e.get("type") == "set" and e.get("kind") == "hard" and e.get("result") == "done":
            used[e["group"]] += 1
        elif e.get("type") == "session":
            for g, n in SESSION_USES[e["what"]].items():
                used[g] += n
    return used


def pick(st, log_entries, rng=random):
    """(kind, group, ladder_id, exercise) for the next challenge."""
    day = today()
    trained = set()
    for e in log_entries:
        if e.get("type") == "session" and e["day"] == day:
            trained |= SESSION_GROUPS[e["what"]]
    used = cap_used(log_entries, week_start(day))
    rested = not trained
    # boss: once a week, on a rest day, in the afternoon
    bossed = any(e.get("kind") == "boss" and week_start(e["day"]) == week_start(day) for e in log_entries)
    if rested and not bossed and dt.datetime.now().hour >= 15 and rng.random() < 0.25:
        ex, _ = rng.choice(BOSSES)
        group = next(g for g, ls in LADDERS.items() for l in ls.values() if ex in l)
        return "boss", group, None, ex
    want_skill = rng.random() < SKILL_SHARE["training" if trained else "rest"]
    last = st.get("last_group")
    start = (ORDER.index(last) + 1) % 4 if last in ORDER else 0
    groups = [g for g in ORDER[start:] + ORDER[:start] if g not in trained and used[g] < CAPS[g]]
    if want_skill or not groups:
        skill = rng.choice(list(SKILLS))
        return "skill", "skill", skill, current(st, skill, SKILLS[skill])
    group = groups[0]
    recent = [e.get("ladder") for e in log_entries[-8:]]
    ladders = list(LADDERS[group].items())
    fresh = [l for l in ladders if l[0] not in recent] or ladders
    ladder_id, ladder = rng.choice(fresh)
    return "hard", group, ladder_id, current(st, ladder_id, ladder)


def streak(log_entries):
    days = {}
    for e in log_entries:
        if e.get("type") == "set" and e.get("result") == "done":
            days[e["day"]] = days.get(e["day"], 0) + 1
    n, d = 0, dt.date.today()
    if days.get(d.isoformat(), 0) < STREAK_MIN:
        d -= dt.timedelta(days=1)
    while days.get(d.isoformat(), 0) >= STREAK_MIN:
        n, d = n + 1, d - dt.timedelta(days=1)
    return n


# ---- conditions -------------------------------------------------------------
def busy():
    if os.path.exists(f"{RUNTIME}/focus-active"):
        return "focus"
    if os.path.exists(f"{RUNTIME}/qs-lock-active"):
        return "locked"
    try:
        run = lambda *a: subprocess.run(list(a), capture_output=True, text=True, timeout=5).stdout
        sources = {s["index"]: s["name"] for s in json.loads(run("pactl", "-f", "json", "list", "sources") or "[]")}
        for so in json.loads(run("pactl", "-f", "json", "list", "source-outputs") or "[]"):
            if not sources.get(so.get("source"), "").endswith(".monitor"):
                return "mic in use"
        if '"node.name": "xdph' in run("pw-dump"):
            return "screen share"
    except (OSError, ValueError, subprocess.TimeoutExpired):
        pass
    return None


# ---- flyouts ------------------------------------------------------------------
def quip(kind):
    return subprocess.run([f"{SCRIPTS}/Pack.sh", "quip", kind], capture_output=True, text=True).stdout.strip()


def flyout(title, sub, extra=None):
    subprocess.run(["qs", "ipc", "call", "osd", "rich", "workout", title, sub, json.dumps(extra or {})],
                   capture_output=True)


def button(label, glyph, *args):
    return {"label": label, "glyph": glyph, "cmd": [SELF, *args]}


def show(st, choice):
    kind, group, ladder_id, ex = choice
    st["pending"] = [kind, group, ladder_id, ex]
    save(st)
    name, cue = EX[ex][0], EX[ex][5]
    if kind == "boss":
        best = st.get("best", {}).get(ex)
        title = f"Boss challenge: {name}" + (f" · beat {best}" if best else "")
        line = quip("boss") or "One all-out set."
    elif kind == "skill":
        title = f"Skill · {ladder_id}: {name} · {amount(st, ex)}"
        line = "Stay fresh, stop well before failure."
    else:
        title = f"{name}: {amount(st, ex)}"
        line = quip("workout")
    flyout(title, (line + " · " if line else "") + cue,
           {"sticky": True, "actions": [button("Done", 0xF012C, "done", ex), button("Skip", 0xF0156, "skip", ex),
                                         button("Later", 0xF0150, "later", ex)]})


def ask_rir(st, ex):
    kind = st["pending"][0] if st.get("pending") else "hard"
    if kind == "boss":
        labels = [("Beat my best", 3), ("Matched it", 1), ("Below", 0)]
        q = "How did the boss go?"
    elif kind == "skill":
        labels = [("Easy", 3), ("Okay", 1), ("Tough", 0)]
        q = "How did the practice feel?"
    else:
        labels = [("3+ left", 3), ("1–2 left", 1), ("Failure", 0)]
        q = "How many reps were left in the tank?"
    glyphs = [0xF0737, 0xF012C, 0xF0238]          # arrow up, check, fire
    flyout(q, f"{EX[ex][0]} · {amount(st, ex)}",
           {"sticky": True, "actions": [button(l, g, "rir", ex, str(v)) for (l, v), g in zip(labels, glyphs)]})


def finish(st, ex, rir):
    pending = st.get("pending") or ["hard", None, None, ex]
    kind, group, ladder_id, _ = pending
    if ladder_id is None:                                       # boss or unknown: find its ladder
        for g, ls in LADDERS.items():
            for lid, l in ls.items():
                if ex in l:
                    group, ladder_id = g, lid
    ladder = (SKILLS if kind == "skill" else LADDERS[group])[ladder_id]
    before = amount(st, ex)
    msg = progress(st, ladder_id, ladder, ex, rir)
    if kind == "boss" and rir >= 3:
        st.setdefault("best", {})[ex] = target(st, ex)
    st["pending"] = None
    if kind != "skill":
        st["last_group"] = group
    st["next_due"] = time.time() + random.randint(*GAP)
    save(st)
    log({"type": "set", "kind": kind, "group": group, "ladder": ladder_id, "ex": ex,
         "amount": before, "rir": rir, "result": "done"})
    all_e = entries()
    done = sum(1 for e in all_e if e["day"] == today() and e.get("type") == "set" and e.get("result") == "done")
    if msg:
        line = quip("levelUp")
        title = (line + " " if line else "") + msg
    else:
        title = quip("workoutDone") or "Nice work!"
    flyout(title, f"{EX[ex][0]} · {done} today · streak {streak(all_e)} d · next: {amount(st, ex)}")


def answer(st, what, ex):
    if ex not in EX:
        return
    pending = st.get("pending") or ["hard", None, None, ex]
    if what == "done":
        ask_rir(st, ex)
    elif what == "later":
        st["next_due"] = time.time() + SNOOZE
        save(st)
    elif what == "skip":
        kind, group, ladder_id, _ = pending
        st["pending"], st["next_due"] = None, time.time() + random.randint(*GAP)
        save(st)
        log({"type": "set", "kind": kind, "group": group, "ladder": ladder_id, "ex": ex,
             "amount": amount(st, ex), "result": "skip"})


def session(what):
    if what not in SESSION_USES:
        return
    log({"type": "session", "what": what})
    groups = ", ".join(sorted(SESSION_GROUPS[what]))
    flyout(f"Logged: {what} session", f"Today's challenges skip {groups} and lean towards skill practice.")


def summary_text():
    all_e = entries()
    sets = [e for e in all_e if e["day"] == today() and e.get("type") == "set" and e.get("result") == "done"]
    used = cap_used(all_e, week_start())
    caps = ", ".join(f"{g} {used[g]}/{CAPS[g]}" for g in ORDER)
    if not sets:
        return "No challenges today", f"Week: {caps}"
    per = {}
    for e in sets:
        per[e["group"]] = per.get(e["group"], 0) + 1
    parts = ", ".join(f"{g} {n}" for g, n in per.items())
    return f"Today: {len(sets)} challenges · streak {streak(all_e)} d", f"{parts} · week: {caps}"


def tick():
    st, now = load(), dt.datetime.now()
    days = st["days"]
    stamp = lambda key: days.get(key) == today()
    for key, (h, m, title, sub) in (("protein", PROTEIN), ("bedtime", BEDTIME)):
        if (now.hour, now.minute) >= (h, m) and not stamp(key) and not (key == "protein" and now.hour >= 23):
            days[key] = today()
            save(st)
            flyout(title, sub)
            return
    if now.hour >= HOURS[1] and not stamp("summary"):
        days["summary"] = today()
        save(st)
        flyout(*summary_text())
        return
    if not HOURS[0] <= now.hour < HOURS[1]:
        return
    last_test = st.get("last_test")
    if not stamp("test_reminder") and (not last_test or (dt.date.today() - dt.date.fromisoformat(last_test)).days >= RETEST_DAYS):
        days["test_reminder"] = today()
        save(st)
        flyout("Time for a max test", "15 minutes to set your targets from your real numbers.",
               {"sticky": True, "actions": [button("Run test", 0xF0538, "test-window"),
                                            {"label": "Not today", "glyph": 0xF0156, "cmd": ["true"]}]})
        return
    if not st["next_due"]:
        st["next_due"] = time.time() + random.randint(5 * 60, 30 * 60)
        save(st)
        return
    if time.time() < st["next_due"] or busy():
        return
    show(st, tuple(st["pending"]) if st.get("pending") else pick(st, entries()))


def test():
    """Interactive max test in a terminal: sets ladders and targets to ~70%."""
    st = load()
    print("\033[1mMax test\033[0m: one all-out set each, rest 2-3 min between. Enter to skip one.\n")
    results = {}
    for ex in TEST:
        name, unit = EX[ex][0], EX[ex][1]
        q = {"s": "seconds", "side": "reps per side", "tries": "tries"}.get(unit, "reps")
        try:
            v = input(f"  {name} — max {q}: ").strip()
        except EOFError:
            return
        if v.isdigit():
            results[ex] = int(v)
    print("\n  One-arm pull-up: where are you?")
    for i, ex in enumerate(SKILLS["one-arm pull-up"]):
        print(f"    {i + 1}. {EX[ex][0]}")
    v = input("  Number (Enter = 1): ").strip()
    st["rung"]["one-arm pull-up"] = int(v) - 1 if v.isdigit() and 1 <= int(v) <= 5 else 0
    for group, ladders in list(LADDERS.items()) + [("skill", SKILLS)]:
        for lid, ladder in ladders.items():
            tested = [ex for ex in ladder if ex in results and results[ex] >= (10 if EX[ex][1] == "s" else 3)]
            if lid == "one-arm pull-up" or not tested:
                continue
            ex = tested[-1]                                   # hardest movement you can do for real
            st["rung"][lid] = ladder.index(ex)
            st["targets"][ex] = max(1, round(results[ex] * (0.5 if group == "skill" else 0.7)))
    st["last_test"] = today()
    st.setdefault("tests", []).append({"day": today(), "results": results})
    save(st)
    log({"type": "test", "results": results})
    print("\n\033[1;32mTargets set.\033[0m Current rungs:")
    stats(st)


def stats(st=None):
    st = st or load()
    all_e = entries()
    used = cap_used(all_e, week_start())
    print(f"\033[1mStreak {streak(all_e)} days · week: " + ", ".join(f"{g} {used[g]}/{CAPS[g]}" for g in ORDER) + "\033[0m\n")
    for group, ladders in list(LADDERS.items()) + [("skills", SKILLS)]:
        print(f"\033[1;34m{group.upper()}\033[0m")
        for lid, ladder in ladders.items():
            ex = current(st, lid, ladder)
            i = ladder.index(ex)
            nxt = f"→ next: {EX[ladder[i + 1]][0]} at {EX[ex][4]}" if i + 1 < len(ladder) else "top of the ladder"
            done = sum(1 for e in all_e if e.get("ex") == ex and e.get("result") == "done")
            print(f"  {EX[ex][0]:46} {amount(st, ex):16} done {done:3}×  \033[33m{nxt}\033[0m")
        print()
    if st.get("tests"):
        last = st["tests"][-1]
        print(f"Last max test {last['day']}: " + ", ".join(f"{EX[k][0]} {v}" for k, v in last["results"].items()))


def today_json():
    st, all_e = load(), entries()
    done = sum(1 for e in all_e if e["day"] == today() and e.get("type") == "set" and e.get("result") == "done")
    skills = {k: EX[current(st, k, v)][0] for k, v in SKILLS.items()}
    print(json.dumps({"done": done, "streak": streak(all_e), "skills": skills,
                      "trained": [e["what"] for e in all_e if e.get("type") == "session" and e["day"] == today()]}))


def selftest():
    st = {"targets": {}, "clean": {}, "rung": {}}
    lad = LADDERS["pull"]["pullup"]
    assert progress(st, "pullup", lad, "c2b", 3) is None and target(st, "c2b") == 11      # 3+ left: up
    for _ in range(2):
        progress(st, "pullup", lad, "c2b", 1)
    assert target(st, "c2b") == 11                                                        # 1-2 left twice: same
    progress(st, "pullup", lad, "c2b", 1)
    assert target(st, "c2b") == 12                                                        # third time: up
    progress(st, "pullup", lad, "c2b", 0)
    assert target(st, "c2b") == 12 and st["clean"]["c2b"] == 0                             # failure: stays
    st["targets"]["c2b"] = 14
    msg = progress(st, "pullup", lad, "c2b", 3)                                           # reaches 15 = top
    assert msg and st["rung"]["pullup"] == 1 and current(st, "pullup", lad) == "explosive"
    wk = week_start()
    logs = [{"day": today(), "type": "session", "what": "upper"}]
    assert cap_used(logs, wk)["push"] == 6
    random.seed(3)
    for _ in range(40):                                                                   # training day: never push/pull
        kind, group, *_ = pick({"rung": {}, "last_group": None}, logs, random)
        assert group not in ("push", "pull")
    logs += [{"day": today(), "type": "set", "kind": "hard", "group": g, "result": "done"}
             for g in ("legs",) * 6 + ("core",) * 6]
    for _ in range(20):                                                                   # all caps full: skills only
        assert pick({"rung": {}, "last_group": None}, logs, random)[0] in ("skill", "boss")
    print("selftest ok")


def main():
    cmd, args = (sys.argv[1] if len(sys.argv) > 1 else "tick"), sys.argv[2:]
    if cmd == "--selftest":
        selftest()
    elif cmd == "tick":
        tick()
    elif cmd == "now":
        st = load()
        show(st, tuple(st["pending"]) if st.get("pending") else pick(st, entries()))
    elif cmd in ("done", "skip", "later") and args:
        answer(load(), cmd, args[0])
    elif cmd == "rir" and len(args) == 2 and args[1].isdigit():
        finish(load(), args[0], int(args[1]))
    elif cmd == "session" and args:
        session(args[0])
    elif cmd == "test":
        test()
    elif cmd == "test-window":
        subprocess.Popen(["kitty", "--class", "updates", "-e", "sh", "-c", f"'{SELF}' test; read -rp 'Enter to close' _"],
                         start_new_session=True)
    elif cmd == "stats":
        stats()
    elif cmd == "summary":
        flyout(*summary_text())
    elif cmd == "today":
        today_json()
    else:
        print(__doc__)


if __name__ == "__main__":
    main()
