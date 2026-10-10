#!/usr/bin/env bash
# Report "└ task" (label minus " · p:<token>") as $short on each firstmate child
# workspace and its panes. Display-only: the real label firstmate matches on is untouched.
set -euo pipefail
herdr=${HERDR_BIN_PATH:-herdr}

"$herdr" workspace list | jq -r '
  .result.workspaces[] | select(.label | test("^└ .+ · p:[A-Za-z0-9_-]{22}$"))
  | [.workspace_id, (.label | sub(" · p:[A-Za-z0-9_-]{22}$"; ""))] | @tsv' |
while IFS=$'\t' read -r ws short; do
  "$herdr" workspace report-metadata "$ws" --source fm-short-label --token "short=$short" >/dev/null
  "$herdr" pane list --workspace "$ws" | jq -r '.result.panes[].pane_id' |
  while read -r pane; do
    "$herdr" pane report-metadata "$pane" --source fm-short-label --token "short=$short" >/dev/null
  done
done
