#!/usr/bin/env bash
set -uo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
actual="$(printf '%s\n' \
  '0.0.0.0 raw.githubusercontent.com ads.example' \
  '0.0.0.0 RAW.GITHUBUSERCONTENT.COM' \
  '0.0.0.0 github.com' \
  | "$root/setup/hosts.sh" --filter)"
expected="$(printf '%s\n' \
  '0.0.0.0 ads.example' \
  '0.0.0.0 github.com')"

if [ "$actual" != "$expected" ]; then
  printf 'FAIL: hosts filter output differs\nExpected:\n%s\nActual:\n%s\n' \
    "$expected" "$actual" >&2
  exit 1
fi

printf '%s\n' 'ok: hosts filter keeps the updater reachable and filters each hostname'
