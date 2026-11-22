#!/usr/bin/env zsh

# Extract most know archives with one command
extract() {
  if [ -f $1 ]; then
    case $1 in
    *.tar.bz2) tar xjf $1 ;;
    *.tar.gz) tar xzf $1 ;;
    *.bz2) bunzip2 $1 ;;
    *.gz) gunzip $1 ;;
    *.tar) tar xf $1 ;;
    *.tbz2) tar xjf $1 ;;
    *.tgz) tar xzf $1 ;;
    *.zip) unzip $1 ;;
    *.Z) uncompress $1 ;;
    # Homebrew's sevenzip formula installs `7zz` only; there is no `7z`.
    *.7z) 7zz x $1 ;;
    *) echo "'$1' cannot be extracted via extract()" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}

# GIT ADD, COMMIT & PUSH
function acp() {
  git add .
  git commit -m "$1"
  git push
}

function compress() {
  tar cvzf $1.tar.gz $1
}

# MAKE FOLDER AND CD INTO IT
mcd() {
  mkdir -p "$@" && cd "$@"
}

# CHECK SHELL
shell() {
  ps | grep $(echo $$) | awk '{ print $4 }'
}

# Create a data URL from a file
function dataurl() {
  local mimeType=$(file -b --mime-type "$1")
  if [[ $mimeType == text/* ]]; then
    mimeType="${mimeType};charset=utf-8"
  fi
  echo "data:${mimeType};base64,$(openssl base64 -in "$1" | tr -d '\n')"
}

# Reload the zsh session, rebuilding the completion dump from scratch.
# (Adapted from OMZ:plugins/zsh_reload.)
#
# Use this after installing something whose completions you want now. The
# normal path only re-scans once every 24h (see zsh_compinit in zsh/zinit.zsh).
#
# The dump path must match the one zsh_compinit uses, or this would rebuild a
# file nothing reads and `zreload` would never refresh anything.
zreload() {
  local dump="${ZINIT[ZCOMPDUMP_PATH]:-${ZSH_CACHE_DIR:-$HOME/.cache/zsh}/zcompdump}"
  autoload -Uz compinit zrecompile

  # Drop the old dump so compinit does a full, unconditional rescan.
  command rm -f "$dump" "$dump.zwc"
  compinit -i -d "$dump"

  # .zshrc byte-compiles itself (and the modules) on each start, so only the
  # dump needs an explicit recompile here.
  zrecompile -p "$dump" && command rm -f "$dump.zwc.old"

  # Use $SHELL if available; remove leading dash if login shell
  [[ -n "$SHELL" ]] && exec ${SHELL#-} || exec zsh
}

# Fuzzy-cd into a subdirectory (not named `fd`, which would shadow the
# `fd` binary that fzf/eza/etc. rely on). `z`/`zi` from zoxide cover most cases.
fcd() {
  local dir
  dir=$(find "${1:-.}" -path '*/\.*' -prune \
    -o -type d -print 2>/dev/null | fzf +m) &&
    cd "$dir"
}

# Runs gh, and for `gh run watch` on a terminal turns off alternate scroll
# (DEC mode 1007) until gh exits.
#
# `gh run watch` draws on the alternate screen but leaves the tty in cooked
# mode and never reads stdin. Ghostty has mode 1007 on by default, which sends
# a wheel or trackpad scroll on the alternate screen as Up/Down arrow keys, so
# every scroll during a watch is echoed as `^[[A^[[B` across the output and
# then replayed into the prompt as history navigation when gh exits. With the
# mode off the scroll sends nothing.
#
# Ghostty has no config option for mode 1007, so it's switched per command.
# `stty -echo` was the other candidate: it hides the characters but they still
# queue up for the prompt.
#
# The restore sits in an `always` block because Ctrl+C is the usual way out of
# a watch, and zsh abandons the rest of a function whose foreground command
# died of SIGINT. A restore on the next line would be skipped, and scrolling
# in less and man would stay dead for the rest of the tab. It writes `h`
# without checking what the mode was before, which is right for Ghostty's
# default; a terminal that doesn't know mode 1007 ignores both writes.
#
# @param $@ gh arguments, passed through untouched
# @return gh's exit status
gh() {
  if [[ $1 != run || $2 != watch || ! -t 1 ]]; then
    command gh "$@"
    return
  fi

  {
    printf '\e[?1007l'
    command gh "$@"
  } always {
    printf '\e[?1007h'
  }
}

