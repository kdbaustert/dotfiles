#!/usr/bin/env bash
#
# Checks that .typos.toml parses, lets through the false alarms and opt-out
# comments it lists, and still catches a real typo. The samples run from a
# scratch directory outside the repo, the way typos runs in another project.
# Run it after changing .typos.toml:
#
#   setup/check-typos.sh
#
# SC2016 is off because the backticks in the grep pattern are typos' output
# quoting, not command substitution.
# shellcheck disable=SC2016
set -uo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
config="$root/.typos.toml"
tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/check-typos.XXXXXX")"
trap 'rm -rf "$tmp_dir"' EXIT

failures=0

# @param $1 description
# @param $2 expected text
# @param $3 actual text
expect() {
  if [ "$2" = "$3" ]; then
    printf 'ok: %s\n' "$1"
  else
    printf 'FAIL: %s\nExpected:\n%s\nActual:\n%s\n' "$1" "$2" "$3" >&2
    failures=$((failures + 1))
  fi
}

# Prints the words typos flags in the given files, one per line, sorted.
#
# @param $@ typos options and files
flagged() {
  typos --format brief "$@" 2>&1 | grep -o 'error: `[^`]*`' | cut -d'`' -f2 | sort
}

if ! command -v typos >/dev/null 2>&1; then
  printf 'FAIL: typos is not on PATH; run brew bundle --file=homebrew/Brewfile\n' >&2
  exit 1
fi

expect 'the config parses' 0 \
  "$(typos --config "$config" --dump-config - >/dev/null 2>&1; printf '%s' "$?")"

cd "$tmp_dir" || exit 1

# The samples are misspelled on purpose, so typos skips this part of the file.
# spellchecker:off
cat >allowed.swift <<'EOF'
// The menu-bar template PNGs, built since Big Sur.
let names = ["caf\u{E9}", "Caf\U00e9", "Caf&#233;", "caf&eacute;"]
// Automattic's shop_order_placehold type, and other look-alikes.
let key = "SidebarTagsSctionDisclosedState"
	W3sic2Vzc2lvbnMiOlt7InRvb2xiYXJJdGVtcyI6W3sia2luZCI6Im1vZGVTd2l0Y2hl
let sample = "teh" // spellchecker:disable-line
EOF
printf 'teh\nI am not sur\n' >typo.txt
mkdir skipped
printf 'teh\n' >skipped/bundle.min.js
printf '{"strings": {"teh": {}}}\n' >skipped/Localizable.xcstrings

expect 'every listed false alarm passes' '' "$(flagged --config "$config" allowed.swift)"
expect 'a real typo is still caught, and "sur" outside "Big Sur"' \
  "$(printf '%s\n' sur teh)" "$(flagged --config "$config" typo.txt)"
# Excludes apply while walking a directory, so walk one instead of naming the
# files.
expect 'minified bundles and .xcstrings catalogs are skipped' '' \
  "$(flagged --config "$config" skipped)"
# spellchecker:on

# Outside the block above, since its "on" line would end that block early.
cat >block.swift <<'EOF'
// spellchecker:off
let sample = "teh"
// spellchecker:on
EOF
expect 'an off/on comment pair skips the lines between' '' \
  "$(flagged --config "$config" block.swift)"

# The real path: typos finds ~/.typos.toml on its own, and a project config
# replaces it instead of merging. Needs a directory under $HOME, and only
# means something on a machine where the link points here.
if [ "$(readlink "$HOME/.typos.toml")" = "$config" ]; then
  home_dir="$(mktemp -d "$HOME/check-typos.XXXXXX")"
  trap 'rm -rf "$tmp_dir" "$home_dir"' EXIT
  printf 'Automattic\n' >"$home_dir/name.txt"
  expect 'Automattic passes through ~/.typos.toml with no --config' '' \
    "$(cd "$home_dir" && flagged name.txt)"
  printf '[default.extend-words]\nteh = "teh"\n' >"$home_dir/_typos.toml" # spellchecker:disable-line
  expect 'a project config replaces ~/.typos.toml' automattic \
    "$(cd "$home_dir" && flagged name.txt | tr '[:upper:]' '[:lower:]')"
else
  echo "skip: ~/.typos.toml is not linked to $config"
fi

if [ "$failures" -gt 0 ]; then
  printf '%d check(s) failed\n' "$failures" >&2
  exit 1
fi
echo 'all typos checks passed'
