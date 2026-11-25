#!/usr/bin/env bash
#
# Runs the `update` function from zsh/os/macos-interactive.zsh against stub
# tools, so nothing real gets upgraded. Each stub appends its name and argv to
# a log, and the checks compare that log with the expected order. Run it after
# changing `update`:
#
#   setup/check-update-function.sh
#
# SC2016 is off because every single-quoted body here (the stub lines and the
# `zsh -c` scripts) is meant to expand later, in the stub or in zsh.
# shellcheck disable=SC2016
set -uo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/update-function.XXXXXX")"
trap 'rm -rf "$tmp_dir"' EXIT

failures=0

# Writes an executable stub that logs "<label> <args>" and exits with
# $STUB_FAIL_<label> (0 when unset).
#
# @param $1 path of the stub to write
# @param $2 label for the log line; defaults to the file name
# @param $3 optional shell lines to run before logging
make_stub() {
  local path="$1"
  local name="${2:-$(basename "$path")}"

  mkdir -p "$(dirname "$path")"
  cat >"$path" <<EOF
#!/bin/bash
${3:-}
printf '%s\n' "$name \$*" >>"\$UPDATE_LOG"
fail_var="STUB_FAIL_${name//-/_}"
exit "\${!fail_var:-0}"
EOF
  chmod +x "$path"
}

# Builds a fresh fake machine under $tmp_dir/<case>: a Homebrew prefix with
# every tool, an nvm dir whose `nvm use` puts its own npm first on PATH, and a
# composer home. Prints the case directory.
#
# @param $1 case name
make_machine() {
  local dir="$tmp_dir/$1"
  local bin="$dir/brew/bin"

  for tool in brew mas pnpm gh nvim; do
    make_stub "$bin/$tool"
  done

  # Logs the first PATH entry so the check can see which node npm would get.
  make_stub "$bin/npm" '' 'printf "%s\n" "homebrew-npm-path ${PATH%%:*}" >>"$UPDATE_LOG"'
  make_stub "$bin/composer" '' '[ "$*" = "global config home" ] && { printf "%s\n" "$COMPOSER_TEST_HOME"; exit 0; }'

  make_stub "$dir/nvm/bin/npm" nvm-npm
  cat >"$dir/nvm/nvm.sh" <<'EOF'
nvm() {
  printf '%s\n' "nvm $*" >>"$UPDATE_LOG"
  [ "$1" = use ] && PATH="$NVM_DIR/bin:$PATH"
  return 0
}
EOF

  mkdir -p "$dir/composer"
  printf '%s\n' "$dir"
}

# Runs `update` in a clean zsh on the fake machine. nvm's bin dir starts PATH,
# as it does in a shell where zsh-nvm has already loaded, so the Homebrew npm
# check only passes when `update` puts Homebrew's bin dir back in front. Extra
# arguments are
# environment assignments. Prints the function's output; the log is
# $dir/log and its exit status lands in $dir/status.
#
# @param $1 case directory from make_machine
# @param $@ VAR=value pairs for this run
run_update() {
  local dir="$1"
  shift

  : >"$dir/log"
  env -i HOME="$dir" TERM=dumb UPDATE_LOG="$dir/log" \
    PATH="$dir/nvm/bin:$dir/brew/bin:/usr/bin:/bin" \
    HOMEBREW_PREFIX="$dir/brew" HOMEBREW_REPOSITORY="$dir/brew" \
    NVM_DIR="$dir/nvm" COMPOSER_TEST_HOME="$dir/composer" "$@" \
    zsh -f -c '
      source "$1"
      zinit() { print -r -- "zinit $*" >>"$UPDATE_LOG"; }
      update
      print -r -- $? >"$2/status"
    ' _ "$root/zsh/os/macos-interactive.zsh" "$dir" 2>&1
}

# Prints the last line of $1 without the color codes print -P adds.
#
# @param $1 captured output
last_line() {
  printf '%s\n' "$1" | tail -1 | perl -pe 's/\e\[[0-9;]*m//g'
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

dir="$(make_machine all-tools)"
output="$(run_update "$dir")"
expect 'every step runs in order and composer is skipped without composer.json' "$(cat <<EOF
brew update
brew upgrade
brew autoremove
brew cleanup
mas upgrade
homebrew-npm-path $dir/brew/bin
npm update -g
nvm use --silent default
nvm-npm install -g npm
nvm-npm update -g
pnpm update -g
gh extension upgrade --all
zinit self-update
zinit update --all
nvim --headless +Lazy! sync +qa
EOF
)" "$(cat "$dir/log")"
expect 'a clean run returns 0' 0 "$(cat "$dir/status")"
expect 'a clean run reports success' '==> Everything updated.' "$(last_line "$output")"

touch "$dir/composer/composer.json"
run_update "$dir" >/dev/null
expect 'composer runs once its global composer.json exists' 'composer global update' \
  "$(grep -x 'composer global update' "$dir/log")"
expect 'phpcs is left alone without any standard' '' "$(grep '^phpcs' "$dir/log")"

neutron="$dir/composer/vendor/automattic/phpcs-neutron-standard"
mkdir -p "$neutron"
make_stub "$dir/composer/vendor/bin/phpcs"
run_update "$dir" >/dev/null
expect 'Neutron is registered again after the composer update' \
  "$(printf '%s\n' 'composer global update' "phpcs --config-set installed_paths $neutron")" \
  "$(grep -A1 -x 'composer global update' "$dir/log")"

vendor="$dir/composer/vendor"
mkdir -p "$vendor/phpcsstandards/phpcsextra" "$vendor/phpcsstandards/phpcsutils" \
  "$vendor/wp-coding-standards/wpcs"
run_update "$dir" >/dev/null
expect 'WPCS and its dependencies stay registered beside Neutron' \
  "phpcs --config-set installed_paths $neutron,$vendor/phpcsstandards/phpcsextra,$vendor/phpcsstandards/phpcsutils,$vendor/wp-coding-standards/wpcs" \
  "$(grep '^phpcs' "$dir/log")"

output="$(run_update "$dir" STUB_FAIL_phpcs=1)"
expect 'a failed registration is named at the end' '==> Failed: phpcs standards' \
  "$(last_line "$output")"

rm "$dir/composer/composer.json"
output="$(run_update "$dir" STUB_FAIL_brew=1 STUB_FAIL_pnpm=3)"
expect 'a failing step returns 1' 1 "$(cat "$dir/status")"
expect 'failures are named at the end' \
  '==> Failed: brew update, brew upgrade, brew autoremove, brew cleanup, pnpm globals' \
  "$(last_line "$output")"
expect 'steps after a failure still run' 'nvim --headless +Lazy! sync +qa' "$(tail -1 "$dir/log")"

dir="$(make_machine brew-only)"
rm "$dir/brew/bin/"{mas,pnpm,gh,nvim,composer,npm}
rm -r "$dir/nvm"
run_update "$dir" >/dev/null
expect 'missing tools are skipped' "$(printf '%s\n' 'brew update' 'brew upgrade' \
  'brew autoremove' 'brew cleanup' 'zinit self-update' 'zinit update --all')" "$(cat "$dir/log")"
expect 'skipped tools are not failures' 0 "$(cat "$dir/status")"

output="$(env -i PATH="/usr/bin:/bin" zsh -f -c \
  'alias update="echo old"; source "$1"; whence -w update' _ "$root/zsh/os/macos-interactive.zsh")"
expect 're-sourcing replaces an old update alias' 'update: function' "$output"

dir="$(make_machine nvm-isolation)"
output="$(env -i HOME="$dir" UPDATE_LOG="$dir/log" PATH="/usr/bin:/bin" NVM_DIR="$dir/nvm" \
  zsh -f -c 'source "$1"; _update_nvm_globals; print -r -- "$PATH"' _ "$root/zsh/os/macos-interactive.zsh")"
expect "nvm use doesn't leak into the calling shell" '/usr/bin:/bin' "$output"

exit "$((failures > 0))"
