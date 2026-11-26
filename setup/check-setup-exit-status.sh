#!/usr/bin/env bash
#
# Runs setup/mas.sh, setup/gh-extensions.sh and setup/macos.sh against stub
# commands and checks their exit status. install.sh reads nothing else from
# them, so a failure that only printed a line used to scroll away with no
# warning in the summary. Run it after changing any of the three:
#
#   setup/check-setup-exit-status.sh
#
# macos.sh runs with every command it changes the system through stubbed:
# defaults, sudo, killall and osascript. It still calls /usr/libexec/PlistBuddy,
# chflags and xattr, but only on paths under HOME, which is the scratch
# directory here.
#
# SC2016 is off because the stub bodies are meant to expand later, in the stub.
# shellcheck disable=SC2016
set -uo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/setup-exit-status.XXXXXX")"
trap 'rm -rf "$tmp_dir"' EXIT

failures=0
bin="$tmp_dir/bin"
log="$tmp_dir/log"
mkdir -p "$bin"

# `mas list` reports Xcode as installed. `mas install <id>` logs the id and
# fails when the id is $STUB_FAIL.
cat >"$bin/mas" <<'EOF'
#!/bin/bash
case "$1" in
  list) printf '497799835 Xcode (16.0)\n' ;;
  install) printf '%s\n' "$2" >>"$STUB_LOG"; [ "$2" != "${STUB_FAIL:-}" ] ;;
esac
EOF

# `gh extension list` prints $STUB_INSTALLED. `gh extension install <ext>`
# fails when the extension is $STUB_FAIL.
cat >"$bin/gh" <<'EOF'
#!/bin/bash
case "$2" in
  list) printf '%s\n' "${STUB_INSTALLED:-}" ;;
  install) [ "$3" != "${STUB_FAIL:-}" ] ;;
esac
EOF

# sudo fails when the command it was given is $STUB_FAIL; defaults exits with
# $STUB_DEFAULTS_EXIT. sleep is cut short so macos.sh's sudo keep-alive loop,
# which holds the captured output open, ends right after the script does.
cat >"$bin/sudo" <<'EOF'
#!/bin/bash
[ "${1:-}" != "${STUB_FAIL:-}" ]
EOF
cat >"$bin/defaults" <<'EOF'
#!/bin/bash
exit "${STUB_DEFAULTS_EXIT:-0}"
EOF
printf '#!/bin/bash\nexit 0\n' >"$bin/killall"
printf '#!/bin/bash\nexit 0\n' >"$bin/osascript"
printf '#!/bin/bash\nprintf "Test Mac\\n"\n' >"$bin/scutil"
printf '#!/bin/bash\n/bin/sleep 0.1\n' >"$bin/sleep"
chmod +x "$bin"/*

# Runs one setup script with only the stubs and the system tools on PATH,
# HOME in the scratch directory, and prints its exit status. The stub log is
# $log.
#
# @param $1 script name in setup/, without .sh
# @param $@ VAR=value pairs for this run
run_script() {
  local script="$root/setup/$1.sh"
  shift
  : >"$log"
  env -i PATH="$bin:/usr/bin:/bin" HOME="$tmp_dir" STUB_LOG="$log" ASSUME_YES=true "$@" \
    "$script" >/dev/null 2>&1
  printf '%s' "$?"
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

# A stub that isn't first on PATH would let macos.sh write this Mac's real
# defaults, so stop before running anything.
for stub in defaults sudo killall osascript; do
  if [ "$(PATH="$bin:/usr/bin:/bin" command -v "$stub")" != "$bin/$stub" ]; then
    printf 'FAIL: the %s stub is not first on PATH\n' "$stub" >&2
    exit 1
  fi
done

expect 'mas.sh exits 0 when every install works' 0 "$(run_script mas)"
expect 'mas.sh skips the app mas list reports' 0 "$(grep -c '^497799835$' "$log")"

expect 'mas.sh exits 1 when one install fails' 1 "$(run_script mas STUB_FAIL=975937182)"
expect 'mas.sh still tries the apps after the failed one' 1 "$(grep -c '^1212019923$' "$log")"

expect 'gh-extensions.sh exits 0 when the install works' 0 "$(run_script gh-extensions)"
expect 'gh-extensions.sh exits 0 when the extension is already there' 0 \
  "$(run_script gh-extensions STUB_INSTALLED='gh dash  dlvhdr/gh-dash  v4.0.0' STUB_FAIL=dlvhdr/gh-dash)"
expect 'gh-extensions.sh exits 1 when an install fails' 1 \
  "$(run_script gh-extensions STUB_FAIL=dlvhdr/gh-dash)"

expect 'macos.sh exits 0 when every sudo step works' 0 "$(run_script macos)"
expect 'macos.sh exits 1 when systemsetup fails' 1 "$(run_script macos STUB_FAIL=systemsetup)"
expect 'macos.sh exits 1 when nvram fails' 1 "$(run_script macos STUB_FAIL=nvram)"
expect 'macos.sh ignores a failed defaults write' 0 "$(run_script macos STUB_DEFAULTS_EXIT=1)"

exit "$((failures > 0))"
