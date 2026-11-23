#!/usr/bin/env bash
#
# Runs the zsh aliases, functions and startup blocks fixed after the zsh
# review against stub commands and checks what they do. Run it after changing
# any of them:
#
#   setup/check-zsh-config.sh
#
# Each case sources one file into `zsh -fi` (-f so no rc file joins in, -i
# because notify.zsh returns early outside an interactive shell and fzf.zsh
# defines zle widgets), then evals the command line, so aliases defined by the
# file expand the way they do at a prompt. The two .zshrc blocks are cut out of
# the file and run alone, because sourcing all of .zshrc would load every
# plugin. The FUNCNEST/LC_ALL case is the exception: it loads the whole
# interactive config through ZDOTDIR, since that's the only way to see the
# environment it leaves.
#
# SC2016 is off because the stub bodies and the zsh scripts are meant to
# expand later, in the stub or in zsh.
# shellcheck disable=SC2016
set -uo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/zsh-config.XXXXXX")"
trap 'rm -rf "$tmp_dir"' EXIT
# macOS's TMPDIR ends in a slash, which leaves a // in the path that pwd
# wouldn't print back.
tmp_dir="$(cd "$tmp_dir" && pwd)"

bin="$tmp_dir/bin"
work="$tmp_dir/work"
log="$tmp_dir/calls.log"
failures=0
mkdir -p "$bin"

# @param $1 stub name
# @param $2 stub body, after the shebang
stub() {
  printf '#!/bin/bash\n%s\n' "$2" >"$bin/$1"
  chmod +x "$bin/$1"
}

# Every stub that stands in for a real tool appends its argv to $log.
stub git 'echo "git $*" >>"$LOG"; [ "$1" = commit ] && exit "${STUB_COMMIT_EXIT:-0}"; exit 0'
stub ngrok 'echo "ngrok $*" >>"$LOG"'
stub brew 'echo "brew $*" >>"$LOG"'
stub sudo 'exec "$@"'
stub npm 'sleep 0.3; echo npm'
stub composer 'echo composer'
stub terminal-notifier 'echo "terminal-notifier $*" >>"$LOG"'
stub lsappinfo 'exit 1'
# The real ps can't be told which PIDs exist, so this one lists the shell
# beside a decoy whose PID starts with the shell's. -p answers for one PID.
stub ps 'if [ "$1" = -p ]; then [ "$2" = "$SHELL_PID" ] && echo -zsh; exit 0; fi
printf "  PID TTY TIME CMD\n%s ttys000 0:00.10 -zsh\n%s7 ttys001 0:00.10 decoy\n" "$SHELL_PID" "$SHELL_PID"'
# Prints $STUB_SCRIPT and exits $STUB_CURL_EXIT, like a curl that fetched (or
# failed to fetch) an install script.
stub curl 'echo "curl $*" >>"$LOG"; printf "%s" "${STUB_SCRIPT:-}"; exit "${STUB_CURL_EXIT:-0}"'

if ! fd_path="$(command -v fd)"; then
  echo "fd not installed (brew install fd); can't check the fzf completers." >&2
  exit 1
fi
ln -s "$fd_path" "$bin/fd"

# Empties the working directory, the home directory and the call log.
fresh() {
  rm -rf "$work" "${tmp_dir:?}/home" "$log"
  mkdir -p "$work" "$tmp_dir/home"
  : >"$log"
}

# Sources a repo file in a clean interactive zsh inside $work, evals a command
# line after it, and prints everything both wrote. SHELL_PID is set for the ps
# stub. TERM_FOR_ZSH and STUB_COMMIT_EXIT in the caller's environment pass
# through.
#
# @param $1 file to source, relative to the repo root
# @param $2 command line
run_zsh() {
  (cd "$work" && env -i PATH="$bin:/usr/bin:/bin" HOME="$tmp_dir/home" LOG="$log" \
    TERM="${TERM_FOR_ZSH:-dumb}" STUB_COMMIT_EXIT="${STUB_COMMIT_EXIT:-0}" \
    zsh -fic 'export SHELL_PID=$$; source "$1"; eval "$2"' _ "$root/$1" "$2" 2>&1)
}

# @param $1 description
# @param $2 expected text
# @param $3 actual text
expect() {
  if [ "$2" = "$3" ]; then
    printf 'ok:   %s\n' "$1"
  else
    printf 'FAIL: %s\nExpected:\n%s\nActual:\n%s\n' "$1" "$2" "$3" >&2
    failures=$((failures + 1))
  fi
}

# @param $1 description
# @param $2 text the output must contain
# @param $3 actual output
expect_text() {
  if [[ $3 == *"$2"* ]]; then
    printf 'ok:   %s\n' "$1"
  else
    printf 'FAIL: %s\nExpected to contain:\n%s\nActual:\n%s\n' "$1" "$2" "$3" >&2
    failures=$((failures + 1))
  fi
}

# @param $1 description
# @param $2 text the output must not contain
# @param $3 actual output
expect_no_text() {
  if [[ $3 != *"$2"* ]]; then
    printf 'ok:   %s\n' "$1"
  else
    printf 'FAIL: %s\nExpected not to contain:\n%s\nActual:\n%s\n' "$1" "$2" "$3" >&2
    failures=$((failures + 1))
  fi
}

# @param $1 description
# @param $@ test(1) expression that has to hold
expect_true() {
  local desc="$1"
  shift
  if test "$@"; then
    printf 'ok:   %s\n' "$desc"
  else
    printf 'FAIL: %s\n  test %s\n' "$desc" "$*" >&2
    failures=$((failures + 1))
  fi
}

# --- zsh/aliases.zsh ----------------------------------------------------------

# .zshrc sources functions.zsh before aliases.zsh, so the ngrok checks do too.
# zsh expands aliases as it parses, so a call after a `source` in the same
# string goes in an inner eval, as it does on the next prompt line.
fresh
run_zsh zsh/functions.zsh "source '$root/zsh/aliases.zsh'; eval 'ngroka TOKEN'" >/dev/null
expect 'ngroka runs ngrok config, not the tunnel' 'ngrok config add-authtoken TOKEN' "$(cat "$log")"

fresh
run_zsh zsh/functions.zsh 'ngrok' >/dev/null
expect 'ngrok alone opens the tunnel on the reserved domain' \
  'ngrok http --url=engaged-obviously-ferret.ngrok-free.app 80' "$(cat "$log")"

fresh
run_zsh zsh/functions.zsh 'NGROK_DOMAIN=other.example ngrok' >/dev/null
expect 'NGROK_DOMAIN replaces the reserved domain' 'ngrok http --url=other.example 80' "$(cat "$log")"

fresh
run_zsh zsh/functions.zsh "source '$root/zsh/aliases.zsh'; eval 'ngrok version'" >/dev/null
expect 'ngrok with arguments runs them as given' 'ngrok version' "$(cat "$log")"

# A shell that still has the old alias and re-sources .zshrc.
fresh
run_zsh zsh/aliases.zsh "alias ngrok='ngrok http 80'; source '$root/zsh/functions.zsh'; eval 'ngrok version'" >/dev/null
expect 're-sourcing drops a leftover ngrok alias' 'ngrok version' "$(cat "$log")"

fresh
expect 'npmc runs composer after npm finishes' "$(printf 'npm\ncomposer')" \
  "$(run_zsh zsh/aliases.zsh npmc)"

fresh
mkdir -p "$work/sub"
touch "$work/.DS_Store" "$work/sub/.DS_Store" "$work/notes.DS_Store"
run_zsh zsh/aliases.zsh dsnuke >/dev/null
expect_true 'dsnuke removes .DS_Store files' ! -e "$work/.DS_Store" -a ! -e "$work/sub/.DS_Store"
expect_true 'dsnuke leaves a file that only ends in .DS_Store' -e "$work/notes.DS_Store"

# "./proj a/node_modules" split on its space is ./proj and a/node_modules.
fresh
mkdir -p "$work/proj" "$work/proj a/node_modules/pkg/node_modules/dep"
touch "$work/proj/keep"
out="$(run_zsh zsh/aliases.zsh cnodeall)"
expect 'cnodeall prints no errors' '' "$out"
expect_true 'cnodeall removes node_modules under a path with a space' ! -e "$work/proj a/node_modules"
expect_true 'cnodeall leaves the directory named by the first half of that path' -e "$work/proj/keep"

fresh
mkdir -p "$work/old app/node_modules/pkg" "$work/new/node_modules/pkg"
touch -t 202001010000 "$work/old app/node_modules"
run_zsh zsh/aliases.zsh cnodeold >/dev/null
expect_true 'cnodeold removes a node_modules older than 4 months' ! -e "$work/old app/node_modules"
expect_true 'cnodeold leaves a fresh node_modules' -e "$work/new/node_modules/pkg"

fresh
mkdir -p "$tmp_dir/home/.ssh/agent"
chmod 700 "$tmp_dir/home/.ssh/agent"
touch "$tmp_dir/home/.ssh/config" "$tmp_dir/home/.ssh/id.pub"
chmod 644 "$tmp_dir/home/.ssh/config" "$tmp_dir/home/.ssh/id.pub"
touch "$tmp_dir/home/real_key"
chmod 644 "$tmp_dir/home/real_key"
ln -s "$tmp_dir/home/real_key" "$tmp_dir/home/.ssh/linked_key"
ln -s "$tmp_dir/home/.ssh/agent" "$tmp_dir/home/.ssh/agent_link"
run_zsh zsh/aliases.zsh chmodssh >/dev/null
expect 'chmodssh sets a symlinked key to 600' '600' "$(stat -f %Lp "$tmp_dir/home/real_key")"
expect 'chmodssh sets files to 600' '600 600' \
  "$(stat -f %Lp "$tmp_dir/home/.ssh/config" "$tmp_dir/home/.ssh/id.pub" | tr '\n' ' ' | sed 's/ $//')"
expect 'chmodssh leaves directories searchable' '700' "$(stat -f %Lp "$tmp_dir/home/.ssh/agent")"

# --- zsh/functions.zsh --------------------------------------------------------

fresh
mkdir -p "$work/d"
echo hi >"$work/d/f"
run_zsh zsh/functions.zsh 'compress d/' >/dev/null
expect_true 'compress d/ writes d.tar.gz beside the directory' -f "$work/d.tar.gz"
expect_true 'compress d/ writes nothing inside the directory' ! -e "$work/d/.tar.gz"
expect 'the archive holds the directory' 'd/f' "$(tar tzf "$work/d.tar.gz" 2>/dev/null | rg -x 'd/f')"
rm -f "$work/d.tar.gz"
run_zsh zsh/functions.zsh 'compress d//' >/dev/null
expect_true 'compress d// writes nothing inside the directory either' -f "$work/d.tar.gz" -a ! -e "$work/d/.tar.gz"

fresh
STUB_COMMIT_EXIT=1 run_zsh zsh/functions.zsh 'acp message' >/dev/null
expect 'acp stops when the commit fails' "$(printf 'git add .\ngit commit -m message')" "$(cat "$log")"

fresh
expect 'shell names this shell only' '-zsh' "$(run_zsh zsh/functions.zsh shell)"

# --- zsh/extra/fzf.zsh --------------------------------------------------------

strip_ansi() {
  sed $'s/\e\\[[0-9;]*m//g'
}

# fzf calls the completers with "." for a bare ** and with the typed directory
# otherwise. The top-level top.txt and top/ are there so a completer that
# searches the current directory instead of the base shows up.
fresh
mkdir -p "$work/a b/sub" "$work/top"
touch "$work/a b/x.txt" "$work/top.txt"
out="$(run_zsh zsh/extra/fzf.zsh '_fzf_compgen_path .' | strip_ansi | sort | tr '\n' ' ')"
expect 'the path completer lists the current directory without ./' 'a b/x.txt top.txt ' "$out"
out="$(run_zsh zsh/extra/fzf.zsh '_fzf_compgen_path "a b"' | strip_ansi)"
expect 'the path completer lists only under a base directory with a space' 'a b/x.txt' "$out"
out="$(run_zsh zsh/extra/fzf.zsh '_fzf_compgen_dir "a b"' | strip_ansi)"
# fd adds the trailing slash when it's given a path; fzf's directory
# completion puts one on every entry anyway.
expect 'the directory completer lists only under a base directory with a space' 'a b/sub/' "$out"
out="$(run_zsh zsh/extra/fzf.zsh "_fzf_compgen_dir '$work'" | strip_ansi)"
expect 'the directory completer lists an absolute base with its prefix' "$work/a b/sub/" \
  "$(printf '%s\n' "$out" | rg -xF "$work/a b/sub/")"

fresh
mkdir -p "$work/c\$(touch pwned)"
run_zsh zsh/extra/fzf.zsh '_fzf_compgen_path "c\$(touch pwned)"' >/dev/null
expect_true 'the path completer runs nothing in a directory name' ! -e "$work/pwned"

# --- zsh/extra/notify.zsh -----------------------------------------------------

fresh
TERM_FOR_ZSH=rio run_zsh zsh/extra/notify.zsh \
  'RIO_NOTIFY_THRESHOLD=0; _rio_notify_preexec "make build"; _rio_notify_precmd' >/dev/null
expect_text 'a finished command notifies in a shell where nothing else loaded zsh/datetime' \
  'make build' "$(cat "$log")"

# --- zsh/zinit.zsh ------------------------------------------------------------

fresh
stub git 'exit 128'
out="$(cd "$work" && env -i PATH="$bin:/usr/bin:/bin" HOME="$tmp_dir/home" \
  XDG_DATA_HOME="$tmp_dir/home/.local/share" \
  zsh -fic 'source "$1"; print -r -- "after: $?"' _ "$root/zsh/zinit.zsh" 2>&1)"
expect_text 'a failed zinit clone says so' 'Clone failed.' "$out"
expect_text 'a failed zinit clone returns to the caller' 'after: 1' "$out"
expect_no_text 'a failed zinit clone sources nothing missing' 'no such file' "$out"
expect_no_text 'a failed zinit clone runs no zinit command' 'command not found' "$out"

# --- .zshrc: starship install -------------------------------------------------

# The block from `if ! command -v starship` to its closing `fi`.
starship_block="$(sed -n '/^if ! command -v starship/,/^fi$/p' "$root/.zshrc")"
if [ -z "$starship_block" ]; then
  echo 'FAIL: no starship install block found in .zshrc' >&2
  failures=$((failures + 1))
fi

# Runs the block with no starship on PATH and prints what it said.
run_starship() {
  env -i PATH="$bin:/usr/bin:/bin" HOME="$tmp_dir/home" LOG="$log" \
    STUB_CURL_EXIT="${STUB_CURL_EXIT:-0}" STUB_SCRIPT="${STUB_SCRIPT:-}" \
    zsh -fc "$starship_block" 2>&1
}

fresh
out="$(STUB_CURL_EXIT=6 run_starship)"
expect_text 'an offline starship install says it failed' 'Install failed.' "$out"
expect_no_text 'an offline starship install is not reported as installed' 'Installation successful.' "$out"
expect_true 'an offline starship install leaves no file behind' ! -e "$tmp_dir/home/.local/bin/starship"
expect_text 'the starship download gives up on a dead connection' '--connect-timeout' "$(cat "$log")"

fresh
out="$(STUB_SCRIPT='exit 0' run_starship)"
expect_text 'an installer that puts no binary there is a failure' 'Install failed.' "$out"

fresh
out="$(STUB_SCRIPT='printf "#!/bin/sh\n" >"$3/starship"; chmod +x "$3/starship"' run_starship)"
expect_text 'an installer that puts a binary there is reported as installed' 'Installation successful.' "$out"
expect_true 'the installed binary is executable' -x "$tmp_dir/home/.local/bin/starship"

# ZSH_CACHE_DIR isn't set here, so the block falls back to ~/.cache/zsh.
stamp="$tmp_dir/home/.cache/zsh/starship-install-failed"

fresh
STUB_CURL_EXIT=6 run_starship >/dev/null
: >"$log"
out="$(STUB_CURL_EXIT=6 run_starship)"
expect_text 'a shell right after a failed install skips it' 'skipping until then' "$out"
expect 'a shell right after a failed install downloads nothing' '' "$(cat "$log")"

fresh
mkdir -p "${stamp%/*}"
touch -t 202001010000 "$stamp"
STUB_CURL_EXIT=6 run_starship >/dev/null
expect_text 'an old failure stamp lets the install retry' 'curl' "$(cat "$log")"

fresh
mkdir -p "${stamp%/*}"
touch -t 202001010000 "$stamp"
STUB_SCRIPT='printf "#!/bin/sh\n" >"$3/starship"; chmod +x "$3/starship"' run_starship >/dev/null
expect_true 'a successful install removes the failure stamp' ! -e "$stamp"

# --- .zshrc: fzf-tab previews -------------------------------------------------

# Every `zstyle ':fzf-tab:complete:...` statement, continuation lines joined.
fzf_tab_styles="$(awk '/^zstyle .:fzf-tab:complete:/ {
    line = $0
    while (line ~ /\\$/) { getline next_line; sub(/\\$/, "", line); line = line next_line }
    print line
  }' "$root/.zshrc")"

# Prints the fzf-preview fzf-tab would look up for a completion context.
#
# @param $1 context after :fzf-tab:, e.g. complete:-parameter-:
preview_for() {
  env -i PATH="/usr/bin:/bin" zsh -fc \
    'eval "$1"; zstyle -s ":fzf-tab:$2" fzf-preview v; print -r -- "$v"' _ "$fzf_tab_styles" "$1"
}

for ctx in -parameter- -brace-parameter- export unset; do
  var_preview="$(preview_for "complete:$ctx:")"
  expect "\$var completion in $ctx previews the value" 'some value' \
    "$(env -i PATH="/usr/bin:/bin" SOME_VAR='some value' word=SOME_VAR zsh -fc "$var_preview")"
done

# NOT_EXPORTED stands in for HISTSIZE and the rest .zshrc sets without export.
expect_text 'a variable the preview shell lacks says why, not a blank pane' 'not set in the preview shell' \
  "$(env -i PATH="/usr/bin:/bin" word=NOT_EXPORTED zsh -fc "$var_preview")"

# fzf-tab exports $word and $group and runs the preview in a zsh -c that has
# none of .zshrc's aliases, which the alias case stands in for.
command_preview="$(preview_for 'complete:-command-:')"
expect 'a command on PATH previews where it resolves' 'ls is /bin/ls' \
  "$(env -i PATH="/usr/bin:/bin" word=ls group='[external command]' zsh -fc "$command_preview")"
expect 'an alias the preview shell lacks previews its group, alone' 'll [alias]' \
  "$(env -i PATH="/usr/bin:/bin" word=ll group='[alias]' zsh -fc "$command_preview")"

# --- .zshenv + .zshrc: environment left for child processes -------------------

# ZDOTDIR points zsh at this tree's .zshenv and .zshrc. FUNCNEST and LC_ALL are
# cleared first because the shell running this script may have exported them.
out="$(env -u FUNCNEST -u LC_ALL ZDOTDIR="$root" zsh -ic \
  'printf "%s|%s|%s" "$FUNCNEST" "$(bash -c "echo \$FUNCNEST")" "$(bash -c "echo \${LC_ALL-unset}")"' \
  2>/dev/null </dev/null | tail -1)"
expect 'FUNCNEST is set in zsh but not exported, and LC_ALL is not set' '5000||unset' "$out"

# --- zsh/os/macos-interactive.zsh ---------------------------------------------

fresh
mkdir -p "$tmp_dir/home/prefix"
out="$(run_zsh zsh/os/macos-interactive.zsh "HOMEBREW_PREFIX=$tmp_dir/home/prefix; brewf; pwd" | tail -1)"
expect 'brewf changes into $HOMEBREW_PREFIX' "$tmp_dir/home/prefix" "$out"
expect 'brewf runs no brew' '' "$(cat "$log")"

echo
if [ "$failures" -eq 0 ]; then
  echo "all checks passed"
fi
exit "$((failures > 0))"
