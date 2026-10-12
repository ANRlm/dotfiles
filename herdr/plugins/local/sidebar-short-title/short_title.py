#!/usr/bin/env python3
"""Publish compact sidebar titles without renaming panes or agent sessions."""
import os
from pathlib import Path
import re
import sys
import unicodedata

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from metadata_refresh import report_metadata, session_snapshot


MAX_COLUMNS = 18


def columns(text):
    # shortcut: emoji sequences are counted conservatively; use grapheme widths if needed.
    return sum(0 if unicodedata.category(c) in {"Mn", "Me", "Cf"}
               else 2 if unicodedata.east_asian_width(c) in {"W", "F"} else 1
               for c in text)


def fit_title(title):
    if columns(title) <= MAX_COLUMNS:
        return title
    result = ""
    for character in title:
        if columns(result + character) > MAX_COLUMNS - 1:
            break
        result += character
    return result.rstrip() + "…"


def compact_title(pane, workspace):
    # A native pane name is an explicit task alias, shared with the pane border.
    if pane.get("label"):
        return fit_title(" ".join(pane["label"].split()))
    title = " ".join((pane.get("terminal_title_stripped") or "").split())
    label = re.sub(r" · p:[A-Za-z0-9_-]{22}$", "", workspace)
    label = re.sub(r"^(?:└ |2ndmate-)", "", label)
    names = {workspace, label}
    for key in ("cwd", "foreground_cwd"):
        if pane.get(key):
            names.add(Path(pane[key]).name)
    for name in sorted(filter(None, names), key=len, reverse=True):
        title = re.sub(r"^" + re.escape(name) + r"(?:\.inbox)?(?:\s+|\s*[:：|·]\s*)",
                       "", title, flags=re.IGNORECASE)
        title = re.sub(r"\s+[|·]\s+" + re.escape(name) + r"$", "", title,
                       flags=re.IGNORECASE)
    return fit_title(title)


def main():
    herdr = os.environ.get("HERDR_BIN_PATH", "herdr")
    source = "sidebar-short-title"
    with session_snapshot(herdr, source) as snapshot:
        labels = {w["workspace_id"]: w["label"] for w in snapshot["workspaces"]}
        for pane in snapshot["panes"]:
            title = compact_title(pane, labels.get(pane["workspace_id"], "")) if pane.get("agent") else ""
            if (pane.get("tokens") or {}).get("sidebar_title", "") == title:
                continue
            report_metadata(herdr, "pane", pane["pane_id"], source, "sidebar_title", title)


if __name__ == "__main__":
    main()
