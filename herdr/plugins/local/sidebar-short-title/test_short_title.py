"""Run with python3; exercises formatting and refreshes without a live Herdr session."""
import json
import subprocess
import tempfile
from unittest.mock import patch

from short_title import columns, compact_title, main


def test():
    examples = [
        ("icsuper-mate.inbox 指令消息处理", "2ndmate-icsuper-mate", "指令消息处理"),
        ("lighthouser-mate 收件箱消息处理", "2ndmate-lighthouser-mate", "收件箱消息处理"),
        ("读取配置并列出优化建议 | dotfiles", "firstmate", "读取配置并列出优…"),
        ("API gateway timeout", "api", "gateway timeout"),
        ("APIary work", "api", "APIary work"),
        ("", "firstmate", ""),
        ("中文" * 20, "firstmate", "中文中文中文中文…"),
        ("a" * 18, "firstmate", "a" * 18),
        ("a" * 19, "firstmate", "a" * 17 + "…"),
        ("e\u0301" * 18, "firstmate", "e\u0301" * 18),
    ]
    for title, workspace, expected in examples:
        actual = compact_title({"terminal_title_stripped": title,
                                "cwd": "/Users/test/dotfiles"}, workspace)
        assert actual == expected, (actual, expected)
        assert columns(actual) <= 18

    for title, cwd in [("Users migration", "/Users/anrlm"),
                       ("test failures", "/src/proj/test/unit")]:
        for key in ("cwd", "foreground_cwd"):
            assert compact_title({"terminal_title_stripped": title, key: cwd}, "proj") == title
    assert compact_title({"terminal_title_stripped": "unit: flaky parser",
                          "foreground_cwd": "/src/proj/test/unit"}, "proj") == "flaky parser"

    named = {"label": "Herdr配置", "terminal_title_stripped": "old task title"}
    assert compact_title(named, "Herdr配置") == "Herdr配置"
    named["terminal_title_stripped"] = "a completely different title"
    assert compact_title(named, "Herdr配置") == "Herdr配置"
    named["label"] = ""
    assert compact_title(named, "project") == "a completely diff…"
    named["label"] = "中文" * 20
    assert compact_title(named, "project") == "中文中文中文中文…"

    panes = [
        {"pane_id": "w1:p1", "workspace_id": "w1", "agent": "claude",
         "terminal_title_stripped": "project task", "tokens": {"sidebar_title": "old"}},
        {"pane_id": "w1:p2", "workspace_id": "w1", "agent": "codex",
         "terminal_title_stripped": "task", "tokens": {"sidebar_title": "task"}},
        {"pane_id": "w1:p3", "workspace_id": "w1", "tokens": {"sidebar_title": "old"}},
    ]
    response = json.dumps({"result": {"snapshot": {
        "workspaces": [{"workspace_id": "w1", "label": "project"}], "panes": panes}}})
    with tempfile.TemporaryDirectory() as tmp, \
            patch.dict("os.environ", {"HOME": tmp, "HERDR_SOCKET_PATH": tmp + "/test.sock"}), \
            patch("metadata_refresh.subprocess.check_output", return_value=response), \
            patch("metadata_refresh.subprocess.run", return_value=subprocess.CompletedProcess([], 0, "", "")) as run:
        main()
        assert run.call_count == 2
        assert run.call_args_list[0].args[0][-2:] == ["--token", "sidebar_title=task"]
        assert run.call_args_list[1].args[0][-2:] == ["--clear-token", "sidebar_title"]
    print("PASS: stable pane aliases, fallback, context removal, generic parents kept, CJK widths, refresh and cleanup")


if __name__ == "__main__":
    test()
