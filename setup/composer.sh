#!/usr/bin/env bash
#
# Global Composer packages, from Composerfile. bash, not sh: the list is a bash
# array, and on a system where /bin/sh is dash (not macOS's bash-in-POSIX-mode)
# the array assignment is a syntax error.
set -uo pipefail

if ! command -v composer >/dev/null 2>&1; then
  echo "composer not found — skipping (install it via the Brewfile first)." >&2
  exit 0
fi

# The list lives in Composerfile so dotsnitch can read it too. A while-read
# loop instead of mapfile, which macOS's bash 3.2 doesn't have.
composer=()
while IFS= read -r line || [ -n "$line" ]; do
  line="${line%%#*}"
  line="${line#"${line%%[![:space:]]*}"}"
  line="${line%"${line##*[![:space:]]}"}"
  [ -n "$line" ] && composer+=("$line")
done < "$(dirname "$0")/Composerfile"

# bash 3.2 treats an empty array as unset under `set -u`.
if [ "${#composer[@]}" -eq 0 ]; then
  echo "Composerfile lists no packages, skipping." >&2
  exit 0
fi

# Idempotent: `composer global require` on an already-present package resolves
# to the same constraint and no-ops, so this doubles as the update path.
composer global require "${composer[@]}"
