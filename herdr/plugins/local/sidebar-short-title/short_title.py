#!/usr/bin/env python3
"""Publish compact sidebar titles without renaming panes or agent sessions."""
import json
import os
from pathlib import Path
import re
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from metadata_refresh import report_metadata, session_snapshot


def manual_tab_ids():
    # herdr has no manual/auto tab-name flag; herdr-automatic-rename records the opt-out.
    state = Path(os.environ.get("XDG_STATE_HOME") or Path.home() / ".local/state")
    state /= "herdr-automatic-rename"
    socket_dir = Path(os.environ.get("HERDR_SOCKET_PATH", "")).parent
    if socket_dir.parent.name == "sessions" and socket_dir.name not in {"", "default"}:
        state /= "sessions/" + socket_dir.name
    try:
        records = json.loads((state / "state.json").read_text())
    except (OSError, ValueError):
        return set()
    return {key for key, record in records.items()
            if ":t" in key and isinstance(record, dict) and record.get("enabled") is False}


def compact_title(pane, workspace, tab_label=""):
    # Herdr truncates by display width to the sidebar's current width.
    # A native pane name is an explicit task alias, shared with the pane border.
    if pane.get("label"):
        return " ".join(pane["label"].split())
    # A manual tab name is the next alias.
    if tab_label.strip():
        return " ".join(tab_label.split())
    title = " ".join((pane.get("terminal_title_stripped") or "").split())
    # pi titles are "π - <session> - <cwd>" or "π - <cwd>".
    title = re.sub(r"^π - ", "", title)
    label = re.sub(r" · p:[A-Za-z0-9_-]{22}$", "", workspace)
    label = re.sub(r"^(?:└ |2ndmate-)", "", label)
    names = {workspace, label}
    for key in ("cwd", "foreground_cwd"):
        if pane.get(key):
            names.add(Path(pane[key]).name)
    for name in sorted(filter(None, names), key=len, reverse=True):
        title = re.sub(r"^" + re.escape(name) + r"(?:\.inbox)?(?:\s+|\s*[:：|·]\s*)",
                       "", title, flags=re.IGNORECASE)
        title = re.sub(r"\s+[|·-]\s+" + re.escape(name) + r"$", "", title,
                       flags=re.IGNORECASE)
    return title


def main():
    herdr = os.environ.get("HERDR_BIN_PATH", "herdr")
    source = "sidebar-short-title"
    with session_snapshot(herdr, source) as snapshot:
        labels = {w["workspace_id"]: w["label"] for w in snapshot["workspaces"]}
        manual = manual_tab_ids()
        agent_tabs = [p.get("tab_id") for p in snapshot["panes"] if p.get("agent")]
        # A tab name shared by several agents cannot tell them apart.
        tabs = {t["tab_id"]: t["label"] for t in snapshot.get("tabs", [])
                if t["tab_id"] in manual and agent_tabs.count(t["tab_id"]) == 1}
        for pane in snapshot["panes"]:
            title = compact_title(pane, labels.get(pane["workspace_id"], ""),
                                  tabs.get(pane.get("tab_id"), "")) if pane.get("agent") else ""
            if (pane.get("tokens") or {}).get("sidebar_title", "") == title:
                continue
            report_metadata(herdr, "pane", pane["pane_id"], source, "sidebar_title", title)


if __name__ == "__main__":
    main()
