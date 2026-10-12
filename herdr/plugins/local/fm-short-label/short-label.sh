#!/usr/bin/env bash
# Preserve the existing plugin and manual refresh entry point.
set -euo pipefail
exec python3 "$(dirname "$0")/short_label.py"
