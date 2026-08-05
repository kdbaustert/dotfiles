#!/usr/bin/env bash
#
# GitHub CLI extensions. `gh extension install` fails on an already-installed
# extension, so skip those — install.sh is meant to be safely re-runnable.
set -uo pipefail

if ! command -v gh >/dev/null 2>&1; then
  echo "gh not found — skipping (install it via the Brewfile first)." >&2
  exit 0
fi

extensions=(
  dlvhdr/gh-dash
)

installed="$(gh extension list 2>/dev/null)"
for ext in "${extensions[@]}"; do
  if printf '%s\n' "$installed" | grep -qF "$ext"; then
    echo "gh extension already installed: $ext"
  else
    gh extension install "$ext"
  fi
done
