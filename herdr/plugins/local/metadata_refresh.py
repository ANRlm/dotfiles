"""Shared locking and CLI error handling for the two local metadata plugins."""
from contextlib import contextmanager
import fcntl
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys


@contextmanager
def session_snapshot(herdr, plugin):
    socket = os.environ.get("HERDR_SOCKET_PATH")
    if not socket:
        socket = json.loads(subprocess.check_output(
            [herdr, "status", "--json"], text=True))["server"]["socket"]
    session = hashlib.sha256(str(Path(socket).resolve()).encode()).hexdigest()
    directory = Path.home() / ".cache/herdr/plugin-locks"
    directory.mkdir(parents=True, exist_ok=True, mode=0o700)
    # Keep the file: unlinking it could let a new caller lock a different inode.
    with (directory / (plugin + "-" + session + ".lock")).open("a") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        snapshot = json.loads(subprocess.check_output(
            [herdr, "api", "snapshot"], text=True))["result"]["snapshot"]
        yield snapshot


def report_metadata(herdr, kind, target, source, token, value):
    metadata = ["--token", token + "=" + value] if value else ["--clear-token", token]
    command = [herdr, kind, "report-metadata", target, "--source", source, *metadata]
    result = subprocess.run(command, text=True, capture_output=True)
    if result.returncode == 0:
        return True
    try:
        code = json.loads(result.stderr)["error"]["code"]
    except (ValueError, KeyError, TypeError):
        code = None
    if code == kind + "_not_found":
        return False
    sys.stderr.write(result.stderr or result.stdout)
    result.check_returncode()
