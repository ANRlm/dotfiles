#!/usr/bin/env python3
"""Refresh Firstmate display labels without changing workspace or tab names."""
import os
from pathlib import Path
import re
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from metadata_refresh import report_metadata, session_snapshot


def main():
    herdr = os.environ.get("HERDR_BIN_PATH", "herdr")
    source = "fm-short-label"
    with session_snapshot(herdr, source) as snapshot:
        panes = {}
        for pane in snapshot["panes"]:
            panes.setdefault(pane["workspace_id"], []).append(pane)
        for workspace in snapshot["workspaces"]:
            label = workspace["label"]
            # Match the sidebar rule; unknown suffix formats remain visible.
            short = re.sub(r" · p:[A-Za-z0-9_-]{22}$", "", label) if label.startswith("└ ") else ""
            target = workspace["workspace_id"]
            if not report_metadata(herdr, "workspace", target, source, "short", short):
                continue
            for pane in panes.get(target, []):
                report_metadata(herdr, "pane", pane["pane_id"], source, "short", short)


if __name__ == "__main__":
    main()
