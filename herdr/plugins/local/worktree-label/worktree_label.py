#!/usr/bin/env python3
"""Publish the linked Git worktree each workspace's agent works in as $worktree and $worktree_status."""
import os
from pathlib import Path
import subprocess
import sys
import time
import traceback

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from metadata_refresh import TIMEOUT, report_metadata, session_snapshot

ICON = "\uf418"  # Nerd Font nf-oct-git_branch; the sidebar fonts are Nerd Fonts.


def git(directory, *args):
    # Raises TimeoutExpired on a hung checkout (network drive, slow hook); the caller skips it.
    return subprocess.run(["git", "--no-optional-locks", "-C", directory, *args], capture_output=True,
                          text=True, errors="replace", timeout=TIMEOUT)


def worktree_tokens(pane, workspace_label=""):
    """Return ($worktree, $worktree_status); both empty outside a linked worktree."""
    # firstmate starts agents in a treehouse worktree from a shell in the main clone,
    # so foreground_cwd is where the work happens and cwd feeds Herdr's own branch token.
    directory = pane.get("foreground_cwd") or pane.get("cwd")
    if not directory:
        return "", ""
    result = git(directory, "rev-parse", "--path-format=absolute", "--git-dir", "--git-common-dir",
                 "--show-toplevel", "--abbrev-ref", "HEAD")
    lines = result.stdout.splitlines()
    # A newline inside a path would shift the fields; show nothing rather than garbage.
    if result.returncode or len(lines) != 4:
        return "", ""
    git_dir, common, top, branch = lines
    if git_dir == common:
        return "", ""
    name = Path(common).name
    label = ICON + " " + (Path(common).parent.name if name == ".git" else name.removesuffix(".git"))
    status = []
    # Herdr's branch and git_status already cover this checkout when cwd is inside it.
    inside = pane.get("cwd") and Path(os.path.realpath(pane["cwd"])).is_relative_to(top)
    if branch != "HEAD" and not inside:
        # Firstmate's fm/<task> branch repeats the task name already in the title.
        if branch.rsplit("/", 1)[-1] not in workspace_label:
            label += " · " + branch
        counts = git(directory, "rev-list", "--left-right", "--count", "@{upstream}...HEAD")
        if counts.returncode == 0 and len(counts.stdout.split()) == 2:
            behind, ahead = counts.stdout.split()
            status += ["↑" + ahead] if ahead != "0" else []
            status += ["↓" + behind] if behind != "0" else []
    # Herdr has no uncommitted-changes token, so this applies to every worktree.
    # --no-optional-locks keeps git from taking index.lock while the agent commits.
    changes = git(directory, "status", "--porcelain")
    changed = len(changes.stdout.splitlines()) if changes.returncode == 0 else 0
    status += ["*" + str(changed)] if changed else []
    # A clean detached checkout the shell itself lives in (a secondmate home) says nothing;
    # a Firstmate task's repo name still matters before its first branch or for scouts.
    if branch == "HEAD" and not status and inside:
        return "", ""
    return label, " ".join(status)


def refresh(herdr):
    """Refresh every workspace; return False if any of them failed."""
    source = "worktree-label"
    ok = True
    with session_snapshot(herdr, source) as snapshot:
        for workspace in snapshot["workspaces"]:
            target = workspace["workspace_id"]
            # One broken workspace must not stop the others from updating.
            try:
                panes = [p for p in snapshot["panes"] if p["workspace_id"] == target]
                panes.sort(key=lambda p: not p.get("agent"))
                values = worktree_tokens(panes[0], workspace.get("label", "")) if panes else ("", "")
                tokens = workspace.get("tokens") or {}
                for token, value in zip(("worktree", "worktree_status"), values):
                    if tokens.get(token, "") != value and not report_metadata(
                            herdr, "workspace", target, source, token, value):
                        break
            except Exception:
                ok = False
                sys.stderr.write("workspace " + target + ":\n" + traceback.format_exc())
    return ok


def main():
    herdr = os.environ.get("HERDR_BIN_PATH", "herdr")
    if sys.argv[1:] != ["--watch"]:
        sys.exit(0 if refresh(herdr) else 1)
    # Agents can work for long stretches without a Herdr event, so poll as well.
    # Herdr does not reap plugin children, and a restarted server reuses the socket, so
    # tie the loop to the server that started it: when that parent exits, so does the loop.
    parent = os.getppid()
    while parent != 1:  # Already orphaned: the server is gone.
        try:
            refresh(herdr)
        except Exception:
            traceback.print_exc()
        for _ in range(20):
            if os.getppid() != parent:
                return
            time.sleep(1)


if __name__ == "__main__":
    main()
