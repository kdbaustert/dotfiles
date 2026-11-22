#!/usr/bin/env bash
#
# Runs the `gh` wrapper from zsh/functions.zsh against a stub gh and checks
# what reaches the terminal: `gh run watch` has to be bracketed by the two
# writes that turn alternate scroll (DEC mode 1007) off and back on, and
# nothing else may be touched. Run it after changing the wrapper:
#
#   setup/check-gh-watch-scroll.sh
#
# The wrapper only acts when stdout is a terminal, so the terminal cases run
# under script(1), which hands zsh a pty. zsh is interactive (-i) there
# because that's the only mode where it abandons a function whose command
# died of SIGINT, which is the case the wrapper's `always` block exists for.
#
# SC2016 is off because the stub body and the `zsh -c` scripts are meant to
# expand later, in the stub or in zsh.
# shellcheck disable=SC2016
set -uo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/gh-watch-scroll.XXXXXX")"
trap 'rm -rf "$tmp_dir"' EXIT

failures=0

# Prints its argv, then dies of $STUB_SIGNAL or exits with $STUB_EXIT.
cat >"$tmp_dir/gh" <<'EOF'
#!/bin/bash
printf '[gh %s]' "$*"
[ -n "${STUB_SIGNAL:-}" ] && kill -s "$STUB_SIGNAL" $$
exit "${STUB_EXIT:-0}"
EOF
chmod +x "$tmp_dir/gh"

# Runs gh through the wrapper on a pty and prints what the terminal received,
# control bytes in `cat -v` form, followed by gh's exit status in angle
# brackets. STUB_EXIT and STUB_SIGNAL in the caller's environment reach the
# stub.
#
# script(1) sees end-of-file on its own stdin at once and passes it on, and
# the pty echoes that as `^D` plus two backspaces. It can land anywhere in the
# output, so it's cut out wherever it is.
#
# @param $@ gh arguments
run_gh_on_terminal() {
  env -i PATH="$tmp_dir:/usr/bin:/bin" TERM=dumb \
    STUB_EXIT="${STUB_EXIT:-0}" STUB_SIGNAL="${STUB_SIGNAL:-}" \
    script -q /dev/null zsh -fic 'source "$1"; shift; gh "$@"; print -n -- "<$?>"' \
    _ "$root/zsh/functions.zsh" "$@" </dev/null | cat -v | sed 's/\^D\^H\^H//g'
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

expect 'run watch on a terminal turns alternate scroll off, then back on' \
  '^[[?1007l[gh run watch -R owner/repo]^[[?1007h<0>' \
  "$(run_gh_on_terminal run watch -R owner/repo)"

expect "gh's exit status survives the wrapper" \
  '^[[?1007l[gh run watch]^[[?1007h<3>' \
  "$(STUB_EXIT=3 run_gh_on_terminal run watch)"

# No status here: zsh drops the rest of the command line along with the rest
# of the function, so the print never runs.
expect 'alternate scroll comes back on when the watch is interrupted' \
  '^[[?1007l[gh run watch]^[[?1007h' \
  "$(STUB_SIGNAL=INT run_gh_on_terminal run watch)"

expect 'other gh commands write no mode change' '[gh run list]<0>' \
  "$(run_gh_on_terminal run list)"

output="$(env -i PATH="$tmp_dir:/usr/bin:/bin" zsh -fc \
  'source "$1"; gh run watch; print -n -- "<$?>"' _ "$root/zsh/functions.zsh" | cat -v)"
expect 'a piped run watch writes no mode change' '[gh run watch]<0>' "$output"

exit "$((failures > 0))"
