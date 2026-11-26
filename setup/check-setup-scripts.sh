#!/usr/bin/env bash
#
# Runs run_setup_scripts from setup/lib.sh against stub scripts in a scratch
# DOTFILES_DIR and checks which ones it runs: every script in the default list
# when SETUP_SCRIPTS is unset, empty or `all`, only the named ones otherwise,
# and the rest still after one fails. Also checks the print helpers install.sh
# reports through: warnings go to stderr and carry the section name into the
# summary, print_summary's status, and the Ctrl-C summary from on_interrupt.
# Run it after changing run_setup_scripts or those helpers:
#
#   setup/check-setup-scripts.sh
#
# SC2016 is off because the `bash -c` body is meant to expand in that shell.
# shellcheck disable=SC2016
set -uo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/setup-scripts.XXXXXX")"
trap 'rm -rf "$tmp_dir"' EXIT

failures=0

# Each stub logs its own name, and exits 1 when it is named in $STUB_FAIL.
mkdir -p "$tmp_dir/setup"
for name in one two three; do
  cat >"$tmp_dir/setup/$name.sh" <<EOF
#!/bin/bash
printf '%s\n' $name >>"\$SETUP_LOG"
[[ " \${STUB_FAIL:-} " == *" $name "* ]] && exit 1
exit 0
EOF
  chmod +x "$tmp_dir/setup/$name.sh"
done

# Sources lib.sh in a clean environment and runs the default list "one two
# three". Extra arguments are environment assignments. Prints what
# run_setup_scripts said; the stubs' log is $tmp_dir/log.
#
# @param $@ VAR=value pairs for this run
run_scripts() {
  : >"$tmp_dir/log"
  env -i PATH="/usr/bin:/bin" HOME="$tmp_dir" SETUP_LOG="$tmp_dir/log" "$@" \
    /bin/bash -c 'source "$1/setup/lib.sh"; DOTFILES_DIR="$2"; run_setup_scripts "one two three"' \
    _ "$root" "$tmp_dir" 2>&1
}

# Sources lib.sh in a clean environment and runs a snippet after it. Prints
# the snippet's stdout, then its exit status in angle brackets; stderr goes to
# $tmp_dir/stderr.
#
# @param $1 bash code to run once lib.sh is loaded
run_lib() {
  env -i PATH="/usr/bin:/bin" HOME="$tmp_dir" \
    /bin/bash -c 'set -u; source "$1/setup/lib.sh"; eval "$2"' _ "$root" "$1" 2>"$tmp_dir/stderr"
  printf '<%s>' "$?"
}

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

all="$(printf '%s\n' one two three)"

run_scripts >/dev/null
expect 'every script runs, in order, when SETUP_SCRIPTS is unset' "$all" "$(cat "$tmp_dir/log")"

run_scripts SETUP_SCRIPTS= >/dev/null
expect 'an empty SETUP_SCRIPTS runs every script too' "$all" "$(cat "$tmp_dir/log")"

run_scripts SETUP_SCRIPTS=all >/dev/null
expect 'SETUP_SCRIPTS=all runs every script' "$all" "$(cat "$tmp_dir/log")"

run_scripts SETUP_SCRIPTS="three one" >/dev/null
expect 'a named list runs only those, in the order given' "$(printf '%s\n' three one)" \
  "$(cat "$tmp_dir/log")"

output="$(run_scripts STUB_FAIL=two)"
expect 'a failing script is reported and the rest still run' "$all" "$(cat "$tmp_dir/log")"
expect 'the failure names the script' 1 "$(grep -c 'setup/two.sh exited non-zero' <<<"$output")"

output="$(run_scripts SETUP_SCRIPTS=missing)"
expect 'an unknown name warns instead of failing' 1 \
  "$(grep -c 'No such setup script: missing' <<<"$output")"

output="$(run_lib 'warning "first"')"
expect 'a warning goes to stderr, not stdout' '<0>' "$output"
expect 'the warning is on stderr' 1 "$(grep -c 'Warning: .*first' "$tmp_dir/stderr")"

output="$(run_lib 'print_summary')"
expect 'print_summary returns 0 with no warnings' 1 "$(grep -c '<0>$' <<<"$output")"

output="$(run_lib 'warning "outside"; CURRENT_SECTION=brew; warning "inside"; print_summary')"
expect 'print_summary returns 1 after a warning' 1 "$(grep -c '<1>$' <<<"$output")"
# Summary lines read "  <color>-<reset> <text>", so each pattern starts at the
# reset code's closing m.
expect 'a warning outside a section has no prefix' 1 "$(grep -c 'm outside$' <<<"$output")"
expect 'a warning inside a section is prefixed with its name' 1 \
  "$(grep -c 'm brew: inside$' <<<"$output")"

output="$(run_lib 'CURRENT_SECTION=zsh; trap on_interrupt INT; kill -INT $$; echo not-reached')"
expect 'Ctrl-C in a section exits 130' 1 "$(grep -c '<130>$' <<<"$output")"
expect 'Ctrl-C prints the summary with the section it stopped in' 1 \
  "$(grep -c 'm zsh: Interrupted' <<<"$output")"
expect 'Ctrl-C stops the run there' 0 "$(grep -c 'not-reached' <<<"$output")"

exit "$((failures > 0))"
