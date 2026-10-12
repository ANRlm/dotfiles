#!/usr/bin/env python3
"""Run with python3; all Herdr calls use a temporary mock, never the live session."""
import json
import os
from pathlib import Path
import subprocess
import tempfile


PLUGIN = Path(__file__).resolve().parent
MOCK = '''#!/usr/bin/env python3
import json, os, sys
from pathlib import Path
path = Path(os.environ["SHORT_LABEL_TEST_STATE"])
state = json.loads(path.read_text())
kind, action, *args = sys.argv[1:]
if [kind, action] == ["api", "snapshot"]:
    print(json.dumps({"result": {"snapshot": state}}))
elif action == "report-metadata":
    assert args[1:3] == ["--source", "fm-short-label"]
    objects = state["workspaces" if kind == "workspace" else "panes"]
    item = next(x for x in objects if x[kind + "_id"] == args[0])
    if args[3] == "--clear-token":
        item["tokens"].pop(args[4], None)
    else:
        assert args[3] == "--token"
        key, value = args[4].split("=", 1)
        item["tokens"][key] = value
    path.write_text(json.dumps(state))
else:
    raise AssertionError(sys.argv)
'''


def main():
    labels = [
        "└ 中文 task · p:abcdefghijklmnopqrstuv",
        "└ future task · p:short",
        "└ plain child",
        "normal · p:abcdefghijklmnopqrstuv",
        "└ quote \\\"\t任务 · p:abcdefghijklmnopqrstuv",
    ]
    expected = ["└ 中文 task", labels[1], labels[2], None, "└ quote \\\"\t任务"]
    state = {"workspaces": [], "panes": []}
    for i, label in enumerate(labels):
        state["workspaces"].append({"workspace_id": f"w{i}", "label": label,
                                    "tokens": {"short": "stale", "other": "keep"}})
        state["panes"].append({"pane_id": f"w{i}:p1", "workspace_id": f"w{i}",
                               "tokens": {"short": "stale", "other": "keep"}})
    with tempfile.TemporaryDirectory() as tmp:
        path = Path(tmp) / "state.json"
        mock = Path(tmp) / "herdr"
        mock.write_text(MOCK)
        mock.chmod(0o755)
        env = dict(os.environ, HERDR_BIN_PATH=str(mock), SHORT_LABEL_TEST_STATE=str(path),
                   HOME=tmp, HERDR_SOCKET_PATH=str(Path(tmp) / "test.sock"))

        def run():
            path.write_text(json.dumps(state))
            subprocess.run(["bash", str(PLUGIN / "short-label.sh")], env=env, check=True)
            return json.loads(path.read_text())

        state = run()
        for objects in state.values():
            for item, short in zip(objects, expected):
                assert item["tokens"].get("short") == short, item
                assert item["tokens"]["other"] == "keep"
        assert run() == state

        state["workspaces"][0]["label"] = "renamed normal"
        state["panes"][2]["workspace_id"] = "w3"
        state["panes"][2]["pane_id"] = "w3:p2"
        state = run()
        assert "short" not in state["workspaces"][0]["tokens"]
        assert "short" not in state["panes"][0]["tokens"]
        assert "short" not in state["panes"][2]["tokens"]
    print("PASS: labels, malformed suffixes, escaping, cleanup, pane moves, idempotence")


if __name__ == "__main__":
    main()
