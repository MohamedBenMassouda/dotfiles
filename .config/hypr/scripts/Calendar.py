#!/usr/bin/env python3
"""Upcoming calendar events for the Quickshell clock popup and reminders.

Reads private iCal addresses from ~/.config/calendar.urls, one per line,
optionally named:  Work|https://calendar.google.com/calendar/ical/.../basic.ics
Google Calendar: Settings > (your calendar) > Integrate calendar >
"Secret address in iCal format". That file is outside the dotfiles repo on
purpose: anyone with the address can read the calendar.

Prints JSON, the next 7 days sorted by start:
  [{"title", "start", "end", "allDay", "calendar", "location"}]
Times are local ISO strings. Downloads are cached for 15 minutes.
Needs: python-recurring-ical-events (pacman).
"""
import hashlib
import json
import sys
import time
import urllib.request
from datetime import date, datetime, timedelta
from pathlib import Path

URLS = Path.home() / ".config" / "calendar.urls"
CACHE = Path.home() / ".cache" / "calendar"
CACHE_SECONDS = 15 * 60
DAYS = 7


def fetch(url):
    """The .ics text, from the cache if it is fresh (or if the download fails)."""
    CACHE.mkdir(parents=True, exist_ok=True)
    path = CACHE / (hashlib.sha1(url.encode()).hexdigest() + ".ics")
    if path.exists() and time.time() - path.stat().st_mtime < CACHE_SECONDS:
        return path.read_text()
    try:
        with urllib.request.urlopen(url, timeout=15) as r:
            text = r.read().decode("utf-8", "replace")
        path.write_text(text)
        return text
    except OSError:
        return path.read_text() if path.exists() else ""


def local(value):
    """(iso string, all-day?) in local time."""
    if isinstance(value, datetime):
        if value.tzinfo:
            value = value.astimezone()
        return value.strftime("%Y-%m-%dT%H:%M"), False
    return value.isoformat(), True


def main():
    try:
        import icalendar
        import recurring_ical_events
    except ImportError:
        print(json.dumps({"error": "install python-recurring-ical-events"}))
        return
    if not URLS.exists():
        print(json.dumps({"error": "no ~/.config/calendar.urls"}))
        return

    today = date.today()
    events = []
    for line in URLS.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        name, _, url = line.rpartition("|") if "|" in line else ("", "", line)
        text = fetch(url)
        if not text:
            continue
        cal = icalendar.Calendar.from_ical(text)
        name = name or str(cal.get("X-WR-CALNAME", ""))
        for ev in recurring_ical_events.of(cal).between(today, today + timedelta(days=DAYS)):
            if str(ev.get("STATUS", "")).upper() == "CANCELLED":
                continue
            start, all_day = local(ev.decoded("DTSTART"))
            end = local(ev.decoded("DTEND"))[0] if "DTEND" in ev else start
            events.append({
                "title": str(ev.get("SUMMARY", "(no title)")),
                "start": start,
                "end": end,
                "allDay": all_day,
                "calendar": name,
                "location": str(ev.get("LOCATION", "")),
            })

    events.sort(key=lambda e: (e["start"], not e["allDay"]))
    print(json.dumps(events, ensure_ascii=False))


if __name__ == "__main__":
    sys.exit(main())
