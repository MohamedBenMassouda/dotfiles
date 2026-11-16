#!/usr/bin/env python3
"""Use a game controller on the desktop (couch mode) and open the game launcher
with its Home button. Started at login (configs/Startup_Apps.lua).

Reads every connected gamepad WITHOUT grabbing it (games still get it as
usual) and, only while no game is running, sends keyboard / mouse input:

  Home        game launcher            Select+Start  couch mode on / off
  left stick  move the pointer         right stick   scroll
  RT / LT     left / right click       L3            middle click
  D-pad       arrow keys               A / B         Enter / Escape
  X           Backspace                Y             workspace overview
  Start       app launcher (Super)     LB / RB       previous / next workspace

"A game is running" = game mode paused the theme pack (the flag file
$XDG_RUNTIME_DIR/desktop-pack-paused, set by GameMode.sh and AutoGameMode.lua).
Needs python-evdev (sudo pacman -S python-evdev).
"""
import os
import selectors
import subprocess
import sys
import time

try:
    import evdev
    from evdev import ecodes as e
except ImportError:
    print("ControllerDesk: python-evdev is missing (sudo pacman -S python-evdev)", file=sys.stderr)
    sys.exit(0)

HOME = os.path.expanduser("~")
RUNTIME = os.environ.get("XDG_RUNTIME_DIR", "/tmp")
GAME_FLAG = f"{RUNTIME}/desktop-pack-paused"
OFF_FLAG = f"{RUNTIME}/controller-desk-off"          # couch mode switched off (Select+Start)
LAUNCHER = f"{HOME}/.config/hypr/UserScripts/GameLauncher.py"
VIRTUAL_NAME = "ControllerDesk virtual input"

DEADZONE = 0.20          # of the stick's range: ignores drift
POINTER_SPEED = 1400     # px per second at full tilt
SCROLL_SPEED = 12        # wheel steps per second at full tilt
TICK = 1 / 120

# button -> key (combo) while couch mode is on
BUTTON_KEYS = {
    e.BTN_SOUTH: [e.KEY_ENTER],                  # A
    e.BTN_EAST: [e.KEY_ESC],                     # B
    e.BTN_NORTH: [e.KEY_BACKSPACE],              # X on Xbox-style pads (BTN_X)
    e.BTN_WEST: [e.KEY_LEFTMETA, e.KEY_A],       # Y: overview (SUPER+A)
    e.BTN_START: [e.KEY_LEFTMETA],               # app launcher (tap SUPER)
    e.BTN_TL: [e.KEY_LEFTMETA, e.KEY_COMMA],     # previous workspace
    e.BTN_TR: [e.KEY_LEFTMETA, e.KEY_DOT],       # next workspace
}
BUTTON_MOUSE = {e.BTN_THUMBL: e.BTN_MIDDLE}
TRIGGER_MOUSE = {e.ABS_RZ: e.BTN_LEFT, e.ABS_Z: e.BTN_RIGHT}
HAT_KEYS = {e.ABS_HAT0X: (e.KEY_LEFT, e.KEY_RIGHT), e.ABS_HAT0Y: (e.KEY_UP, e.KEY_DOWN)}


def toast(kind, title, sub=""):
    subprocess.Popen(["qs", "ipc", "call", "osd", "toast", kind, title, sub],
                     stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def is_gamepad(dev):
    caps = dev.capabilities()
    return (dev.name != VIRTUAL_NAME and e.BTN_SOUTH in caps.get(e.EV_KEY, [])
            and any(a == e.ABS_X or (isinstance(a, tuple) and a[0] == e.ABS_X) for a in caps.get(e.EV_ABS, [])))


class Pad:
    def __init__(self, dev):
        self.dev = dev
        self.axes = {}           # code -> (value, min, max)
        for code, info in dev.capabilities(absinfo=True).get(e.EV_ABS, []):
            self.axes[code] = [info.value, info.min, info.max]
        self.held = set()

    def norm(self, code):
        """-1..1 for sticks, 0..1 for triggers (min 0)."""
        if code not in self.axes:
            return 0.0
        v, lo, hi = self.axes[code]
        if lo >= 0 and code in TRIGGER_MOUSE:
            return (v - lo) / max(1, hi - lo)
        mid = (lo + hi) / 2
        return (v - mid) / max(1, (hi - lo) / 2)


def stick(x, y):
    """Dead zone + curve: small tilts are precise, full tilt is fast."""
    mag = (x * x + y * y) ** 0.5
    if mag < DEADZONE:
        return 0.0, 0.0
    scaled = ((mag - DEADZONE) / (1 - DEADZONE)) ** 1.8
    return x / mag * scaled, y / mag * scaled


def main():
    out = evdev.UInput({
        e.EV_KEY: sorted({k for keys in BUTTON_KEYS.values() for k in keys}
                         | {k for pair in HAT_KEYS.values() for k in pair}
                         | {e.BTN_LEFT, e.BTN_RIGHT, e.BTN_MIDDLE}),
        e.EV_REL: [e.REL_X, e.REL_Y, e.REL_WHEEL, e.REL_HWHEEL],
    }, name=VIRTUAL_NAME)

    sel = selectors.DefaultSelector()
    pads = {}                 # path -> Pad
    last_scan = 0
    acc = {"x": 0.0, "y": 0.0, "wheel": 0.0, "hwheel": 0.0}
    trigger_down = {code: False for code in TRIGGER_MOUSE}
    moving = False            # a stick is tilted: tick at 120 Hz, otherwise wait for events

    def active():
        return not os.path.exists(GAME_FLAG) and not os.path.exists(OFF_FLAG)

    def press(keys, down):
        for k in (keys if down else reversed(keys)):
            out.write(e.EV_KEY, k, 1 if down else 0)
        out.syn()

    def release_all(pad):
        for keys in list(pad.held):
            press(list(keys), False)
        pad.held.clear()

    while True:
        now = time.monotonic()
        if now - last_scan > 3:                            # hotplug
            last_scan = now
            paths = set(evdev.list_devices())
            for path in list(pads):
                if path not in paths:
                    sel.unregister(pads[path].dev)
                    del pads[path]
            for path in paths - set(pads):
                try:
                    dev = evdev.InputDevice(path)
                    if is_gamepad(dev):
                        pads[path] = Pad(dev)
                        sel.register(dev, selectors.EVENT_READ, pads[path])
                    else:
                        dev.close()
                except OSError:
                    pass

        for key, _ in sel.select(timeout=TICK if moving else 3):
            pad = key.data
            try:
                events = list(pad.dev.read())
            except OSError:                                # unplugged
                sel.unregister(pad.dev)
                pads.pop(pad.dev.path, None)
                continue
            for ev in events:
                if ev.type == e.EV_ABS and ev.code in pad.axes:
                    pad.axes[ev.code][0] = ev.value
                    if not active():
                        continue
                    if ev.code in HAT_KEYS:
                        neg, pos = HAT_KEYS[ev.code]
                        out.write(e.EV_KEY, neg, 1 if ev.value < 0 else 0)
                        out.write(e.EV_KEY, pos, 1 if ev.value > 0 else 0)
                        out.syn()
                    elif ev.code in TRIGGER_MOUSE:
                        down = pad.norm(ev.code) > 0.5
                        if down != trigger_down[ev.code]:
                            trigger_down[ev.code] = down
                            out.write(e.EV_KEY, TRIGGER_MOUSE[ev.code], int(down))
                            out.syn()
                elif ev.type == e.EV_KEY:
                    down = ev.value != 0
                    keys_now = pad.dev.active_keys()
                    if ev.code == e.BTN_MODE and down and not os.path.exists(GAME_FLAG):
                        subprocess.Popen([LAUNCHER], start_new_session=True)
                        continue
                    if ev.code in (e.BTN_START, e.BTN_SELECT) and down \
                            and e.BTN_START in keys_now and e.BTN_SELECT in keys_now:
                        release_all(pad)
                        if os.path.exists(OFF_FLAG):
                            os.remove(OFF_FLAG)
                            toast("controller", "Couch mode on", "The controller drives the desktop")
                        else:
                            open(OFF_FLAG, "w").close()
                            toast("controller-off", "Couch mode off", "Select+Start turns it back on")
                        continue
                    if not active() and down:
                        continue
                    if ev.code in BUTTON_KEYS:
                        keys = tuple(BUTTON_KEYS[ev.code])
                        if down:
                            pad.held.add(keys)
                        else:
                            pad.held.discard(keys)
                        press(list(keys), down)
                    elif ev.code in BUTTON_MOUSE:
                        out.write(e.EV_KEY, BUTTON_MOUSE[ev.code], int(down))
                        out.syn()

        if not active():
            for pad in pads.values():
                release_all(pad)
            moving = False
            continue
        # pointer and scroll from the sticks of every connected pad
        moving = False
        for pad in pads.values():
            mx, my = stick(pad.norm(e.ABS_X), pad.norm(e.ABS_Y))
            sx, sy = stick(pad.norm(e.ABS_RX), pad.norm(e.ABS_RY))
            moving = moving or any((mx, my, sx, sy))
            acc["x"] += mx * POINTER_SPEED * TICK
            acc["y"] += my * POINTER_SPEED * TICK
            acc["hwheel"] += sx * SCROLL_SPEED * TICK
            acc["wheel"] -= sy * SCROLL_SPEED * TICK
        moved = False
        for name, code in (("x", e.REL_X), ("y", e.REL_Y), ("wheel", e.REL_WHEEL), ("hwheel", e.REL_HWHEEL)):
            whole = int(acc[name])
            if whole:
                out.write(e.EV_REL, code, whole)
                acc[name] -= whole
                moved = True
        if moved:
            out.syn()


if __name__ == "__main__":
    main()
