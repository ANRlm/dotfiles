"""Offline process-level regression checks for both metadata plugins."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import time


ROOT = Path(__file__).resolve().parent
MOCK = r'''#!/usr/bin/env python3
import json, os, sys, time
from pathlib import Path
root = Path(os.environ["REFRESH_TEST_DIR"])
args = sys.argv[1:]
run = os.environ.get("REFRESH_TEST_RUN", "new")
with (root / "calls").open("a") as f:
    f.write(json.dumps([run, args]) + "\n")
snapshot = {
    "workspaces": [
        {"workspace_id": "w1", "label": "└ " + run},
        {"workspace_id": "w2", "label": "└ survivor"}],
    "panes": [
        {"pane_id": "w1:p1", "workspace_id": "w1", "agent": "codex", "label": run,
         "terminal_title_stripped": run},
        {"pane_id": "w2:p1", "workspace_id": "w2", "agent": "claude", "label": "survivor",
         "terminal_title_stripped": "survivor"}]}
if args in (["api", "snapshot"], ["workspace", "list"]):
    (root / (run + "-read")).touch()
    if run == "old":
        deadline = time.monotonic() + 10
        while not (root / "release").exists():
            if time.monotonic() > deadline: sys.exit(90)
            time.sleep(.01)
    result = {"snapshot": snapshot} if args[0] == "api" else {"workspaces": snapshot["workspaces"]}
elif args[:2] == ["pane", "list"]:
    result = {"panes": [p for p in snapshot["panes"] if p["workspace_id"] == args[3]]}
elif args[1] == "report-metadata":
    failure = os.environ.get("REFRESH_TEST_FAILURE", "")
    if args[2] == os.environ.get("REFRESH_TEST_GONE", ""):
        print(json.dumps({"error": {"code": failure, "message": "test failure"}}), file=sys.stderr)
        sys.exit(1)
    result = {}
else:
    raise AssertionError(args)
print(json.dumps({"result": result}))
'''


def wait_for(path):
    deadline = time.monotonic() + 5
    while not path.exists():
        if time.monotonic() > deadline:
            raise AssertionError("timed out waiting for " + str(path))
        time.sleep(.01)


def check(command, token, gone_id, failure):
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        mock = root / "herdr"
        mock.write_text(MOCK)
        mock.chmod(0o755)
        env = dict(os.environ, HERDR_BIN_PATH=str(mock), HERDR_SOCKET_PATH=str(root / "session.sock"),
                   HOME=tmp, XDG_STATE_HOME=tmp, REFRESH_TEST_DIR=tmp, PYTHONDONTWRITEBYTECODE="1")
        old = subprocess.Popen(command, env=dict(env, REFRESH_TEST_RUN="old"), stderr=subprocess.PIPE)
        new = None
        try:
            wait_for(root / "old-read")
            new = subprocess.Popen(command, env=dict(env, REFRESH_TEST_RUN="new"), stderr=subprocess.PIPE)
            # A competing snapshot must stay behind the first writer's lock.
            time.sleep(.5)
            read_while_locked = (root / "new-read").exists()
            (root / "release").touch()
            assert old.communicate(timeout=10)[1] == b"" and old.returncode == 0
            assert new.communicate(timeout=10)[1] == b"" and new.returncode == 0
            calls = [json.loads(line) for line in (root / "calls").read_text().splitlines()]
            writes = [(run, args) for run, args in calls if args[1] == "report-metadata" and args[2] == "w1:p1"]
            assert not read_while_locked, "second refresh read its snapshot before the first completed"
            assert writes[-1][0] == "new", "older refresh overwrote the newer value"
            assert token + "=new" in writes[-1][1] or token + "=└ new" in writes[-1][1]
        finally:
            (root / "release").touch()
            for process in (old, new):
                if process is not None and process.poll() is None:
                    process.kill()
                    process.communicate()

        (root / "calls").write_text("")
        result = subprocess.run(command, env=dict(env, REFRESH_TEST_GONE=gone_id,
                                REFRESH_TEST_FAILURE=failure), capture_output=True, text=True)
        assert result.returncode == 0, result.stderr
        calls = [json.loads(line)[1] for line in (root / "calls").read_text().splitlines()]
        assert any(args[:3] == ["pane", "report-metadata", "w2:p1"] for args in calls)

        result = subprocess.run(command, env=dict(env, REFRESH_TEST_GONE=gone_id,
                                REFRESH_TEST_FAILURE="permission_denied"), capture_output=True, text=True)
        assert result.returncode != 0 and "permission_denied" in result.stderr
        result = subprocess.run(command, env=env, capture_output=True, text=True, timeout=5)
        assert result.returncode == 0, "lock was not released after an error: " + result.stderr


def check_session_isolation(command):
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        mock = root / "herdr"
        mock.write_text(MOCK)
        mock.chmod(0o755)
        env = dict(os.environ, HERDR_BIN_PATH=str(mock), HOME=tmp, XDG_STATE_HOME=tmp, REFRESH_TEST_DIR=tmp,
                   PYTHONDONTWRITEBYTECODE="1")
        old = subprocess.Popen(command, env=dict(env, REFRESH_TEST_RUN="old",
                               HERDR_SOCKET_PATH=str(root / "first.sock")), stderr=subprocess.PIPE)
        try:
            wait_for(root / "old-read")
            other = subprocess.run(command, env=dict(env, REFRESH_TEST_RUN="new",
                                   HERDR_SOCKET_PATH=str(root / "second.sock")),
                                   capture_output=True, text=True, timeout=5)
            assert other.returncode == 0, other.stderr
            assert not (root / "release").exists()
        finally:
            (root / "release").touch()
            old.communicate(timeout=10)
        assert old.returncode == 0


if __name__ == "__main__":
    check(["python3", str(ROOT / "sidebar-short-title/short_title.py")], "sidebar_title", "w1:p1", "pane_not_found")
    check(["bash", str(ROOT / "fm-short-label/short-label.sh")], "short", "w1", "workspace_not_found")
    check(["bash", str(ROOT / "fm-short-label/short-label.sh")], "short", "w1:p1", "pane_not_found")
    check_session_isolation(["python3", str(ROOT / "sidebar-short-title/short_title.py")])
    check_session_isolation(["bash", str(ROOT / "fm-short-label/short-label.sh")])
    print("PASS: queued fresh snapshots; session isolation; vanished objects skipped; errors reported and locks released")
