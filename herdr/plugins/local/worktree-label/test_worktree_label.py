#!/usr/bin/env python3
"""Run with python3; Git runs in a temporary repo, Herdr calls use a mock, never the live session."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import time


PLUGIN = Path(__file__).resolve().parent
ICON = "\uf418"
MOCK = '''#!/usr/bin/env python3
import json, os, sys
from pathlib import Path
path = Path(os.environ["WORKTREE_TEST_STATE"])
state = json.loads(path.read_text())
kind, action, *args = sys.argv[1:]
if [kind, action] == ["api", "snapshot"]:
    print(json.dumps({"result": {"snapshot": state}}))
elif [kind, action] == ["workspace", "report-metadata"]:
    if args[0] == os.environ.get("WORKTREE_TEST_FAIL"):
        print(json.dumps({"error": {"code": "permission_denied"}}), file=sys.stderr)
        sys.exit(1)
    with open(os.environ["WORKTREE_TEST_LOG"], "a") as log:
        log.write(args[0] + "\\n")
    assert args[1:3] == ["--source", "worktree-label"]
    item = next(x for x in state["workspaces"] if x["workspace_id"] == args[0])
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
    # Keep the user's global and system git config (hooks, signing) out of the test repos.
    os.environ.update(GIT_CONFIG_GLOBAL="/dev/null", GIT_CONFIG_NOSYSTEM="1")
    with tempfile.TemporaryDirectory() as tmp:
        tmp = Path(os.path.realpath(tmp))
        repo, task, detached, plain = tmp / "erp-admin", tmp / "wt/1/task", tmp / "wt/2/home", tmp / "plain"
        git = ["git", "-c", "user.name=t", "-c", "user.email=t@t"]
        subprocess.run(git + ["init", "-q", "-b", "master", str(repo)], check=True)
        subprocess.run(git + ["-C", str(repo), "commit", "-q", "--allow-empty", "-m", "init"], check=True)
        subprocess.run(git + ["-C", str(repo), "worktree", "add", "-q", "-b", "fm/task", str(task)], check=True)
        subprocess.run(git + ["-C", str(repo), "worktree", "add", "-q", "--detach", str(detached)], check=True)
        # fm/task tracks master: one commit ahead, one behind.
        subprocess.run(git + ["-C", str(task), "branch", "-q", "-u", "master"], check=True)
        subprocess.run(git + ["-C", str(task), "commit", "-q", "--allow-empty", "-m", "a"], check=True)
        subprocess.run(git + ["-C", str(repo), "commit", "-q", "--allow-empty", "-m", "b"], check=True)
        clean = tmp / "wt/3/clean"
        subprocess.run(git + ["-C", str(repo), "worktree", "add", "-q", "--detach", str(clean)], check=True)
        (task / "sub").mkdir()
        plain.mkdir()
        # Uncommitted files count even on a detached worktree; the empty sub/ dir does not.
        (detached / "a").write_text("a")
        (detached / "b").write_text("b")

        panes = [
            # firstmate child: shell in the main clone, agent in a worktree subdirectory.
            ("w1", {"cwd": str(repo), "foreground_cwd": str(task / "sub"), "agent": "codex"}),
            # Herdr's branch and git_status already cover a pane whose shell is in the worktree.
            ("w2", {"cwd": str(task), "foreground_cwd": str(task)}),
            ("w3", {"cwd": str(detached), "foreground_cwd": str(detached), "agent": "claude"}),
            ("w4", {"cwd": str(repo), "foreground_cwd": str(repo)}),
            ("w5", {"cwd": str(plain)}),
            # The agent pane wins over a plain shell elsewhere in the workspace.
            ("w6", {"cwd": str(plain)}),
            ("w6", {"cwd": str(repo), "foreground_cwd": str(task), "agent": "pi"}),
            # A clean detached worktree (a secondmate home) shows nothing.
            ("w8", {"cwd": str(clean), "foreground_cwd": str(clean), "agent": "claude"}),
            # A Firstmate scout or unbranched task still names its repo.
            ("w9", {"cwd": str(repo), "foreground_cwd": str(clean), "agent": "codex"}),
        ]
        wt = ICON + " erp-admin"
        expected = {"w1": (wt, "↑1 ↓1"), "w2": (wt, None), "w3": (wt, "*2"), "w4": (None, None),
                    "w5": (None, None), "w6": (wt + " · fm/task", "↑1 ↓1"), "w7": (None, None),
                    "w8": (None, None), "w9": (wt, None)}
        # The branch is dropped when the title already names the task.
        labels = {"w1": "└ task · p:abcdefghijklmnopqrstuv"}
        state = {"workspaces": [{"workspace_id": w, "label": labels.get(w, "other"),
                                 "tokens": {"worktree": "stale", "worktree_status": "stale",
                                            "other": "keep"}}
                                for w in expected],
                 "panes": [dict(p, pane_id=w + ":p" + str(i), workspace_id=w)
                           for i, (w, p) in enumerate(panes)]}
        path, log, mock = tmp / "state.json", tmp / "writes.log", tmp / "herdr"
        mock.write_text(MOCK)
        mock.chmod(0o755)
        env = dict(os.environ, HERDR_BIN_PATH=str(mock), WORKTREE_TEST_STATE=str(path),
                   WORKTREE_TEST_LOG=str(log), HOME=str(tmp), HERDR_SOCKET_PATH=str(tmp / "test.sock"),
                   PYTHONDONTWRITEBYTECODE="1")

        def run():
            path.write_text(json.dumps(state))
            log.write_text("")
            subprocess.run(["python3", str(PLUGIN / "worktree_label.py")], env=env, check=True)
            return json.loads(path.read_text())

        def tokens(workspace):
            item = next(x for x in state["workspaces"] if x["workspace_id"] == workspace)
            return item["tokens"].get("worktree"), item["tokens"].get("worktree_status")

        state = run()
        for workspace in state["workspaces"]:
            assert tokens(workspace["workspace_id"]) == expected[workspace["workspace_id"]], workspace
            assert workspace["tokens"]["other"] == "keep"
        assert run() == state
        assert log.read_text() == ""
        subprocess.run(git + ["-C", str(task), "branch", "-q", "--unset-upstream"], check=True)
        state = run()
        assert tokens("w6") == (wt + " · fm/task", None)
        (task / "c").write_text("c")
        state = run()
        assert tokens("w2") == (wt, "*1")

        # One failing workspace still lets the rest update, and the run reports the failure.
        for workspace in state["workspaces"]:
            workspace["tokens"] = {}
        path.write_text(json.dumps(state))
        failed = subprocess.run(["python3", str(PLUGIN / "worktree_label.py")], capture_output=True,
                                env=dict(env, WORKTREE_TEST_FAIL="w1"), text=True)
        assert failed.returncode == 1 and "permission_denied" in failed.stderr
        state = json.loads(path.read_text())
        assert tokens("w1") == (None, None) and tokens("w6") == (wt + " · fm/task", "*1")

        # --watch survives refresh errors but exits once the process that started it is gone.
        path.write_text("not json")
        starter = subprocess.run(["sh", "-c", 'python3 "$0" --watch >/dev/null 2>&1 & echo $!; sleep 1',
                                  str(PLUGIN / "worktree_label.py")], env=env, capture_output=True,
                                 text=True, check=True)
        pid = int(starter.stdout)
        deadline = time.monotonic() + 10
        while time.monotonic() < deadline:
            try:
                os.kill(pid, 0)
            except ProcessLookupError:
                break
            time.sleep(.2)
        else:
            os.kill(pid, 9)
            raise AssertionError("--watch outlived its parent")
    print("PASS: worktree child, task-named branch, ahead/behind, uncommitted count, no upstream, "
          "shell-covered branch, detached dirty/clean, main clone, non-git, agent priority, "
          "idempotence, per-workspace failure, watch exits with its parent")

if __name__ == "__main__":
    main()
