#!/usr/bin/env python3
"""Update the system, showing unread Arch Linux news first.

Arch posts news when an update needs a manual step; reading it before
`yay -Syu` avoids most breakage. Used by the bar (Updates tile / count).

  ArchUpdate.py            show unread news, ask, then run yay -Syu
  ArchUpdate.py --unread   print how many news items are unread (for the bar)

What you've read is remembered in ~/.local/state/arch-news-seen.
"""
import html
import re
import subprocess
import sys
import urllib.request
import xml.etree.ElementTree as ET
from email.utils import parsedate_to_datetime
from pathlib import Path

FEED = "https://archlinux.org/feeds/news/"
SEEN = Path.home() / ".local/state/arch-news-seen"


def news():
    """[(date, title, link, text)] newest first; [] if offline."""
    try:
        with urllib.request.urlopen(FEED, timeout=10) as r:
            root = ET.fromstring(r.read())
    except Exception:
        return []
    items = []
    for it in root.iter("item"):
        date = parsedate_to_datetime(it.findtext("pubDate"))
        text = html.unescape(re.sub(r"<[^>]+>", "", it.findtext("description") or ""))
        items.append((date, it.findtext("title"), it.findtext("link"), text.strip()))
    return sorted(items, reverse=True)


def seen():
    try:
        return parsedate_to_datetime(SEEN.read_text().strip())
    except Exception:
        return None


def unread(items):
    last = seen()
    if last is None:            # first run: only the latest few matter
        return items[:2]
    return [i for i in items if i[0] > last]


def mark_read(items):
    if items:
        SEEN.parent.mkdir(parents=True, exist_ok=True)
        SEEN.write_text(items[0][0].strftime("%a, %d %b %Y %H:%M:%S %z"))


def main():
    items = news()
    if "--unread" in sys.argv:
        print(len(unread(items)))
        return

    new = unread(items)
    if new:
        print("\033[1;33m== Arch Linux news since your last update ==\033[0m\n")
        for date, title, link, text in reversed(new):
            print(f"\033[1m{date:%Y-%m-%d}  {title}\033[0m\n{link}\n")
            print(re.sub(r"\n{3,}", "\n\n", text)[:2000], "\n")
        if input("Read it? Continue with the update [Y/n] ").strip().lower().startswith("n"):
            print("Update cancelled; the news stays unread.")
            return
        mark_read(items)
    elif items:
        mark_read(items)

    subprocess.call(["yay", "-Syu"])


if __name__ == "__main__":
    main()
