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
    # 7-Zip's binary is named differently per platform and neither name exists
    # on the other: Homebrew's sevenzip formula installs `7zz` only, Arch's
    # 7zip package installs `7z` only. Resolved through zsh's $commands hash at
    # call time rather than branched on $DOTFILES_OS — the question here is
    # genuinely "which binary is installed", not "which OS is this", and the
    # hash answers it in-process with no fork.
    *.7z) "${commands[7zz]:-7z}" x $1 ;;
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
# Use this after installing something whose completions you want *now* — the
# normal path only re-scans once every 24h (see zsh_compinit in zsh/zinit.zsh).
#
# The dump path must match the one zsh_compinit uses, or this would rebuild a
# file nothing reads: it previously wrote "$ZSH_CACHE_DIR/zcomp-$HOST" while
# compinit read ~/.zcompdump, so `zreload` never actually refreshed anything.
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

# Fuzzy-cd into a subdirectory (renamed from `fd` so it no longer shadows the
# `fd` binary that fzf/eza/etc. rely on). `z`/`zi` from zoxide cover most cases.
fcd() {
  local dir
  dir=$(find "${1:-.}" -path '*/\.*' -prune \
    -o -type d -print 2>/dev/null | fzf +m) &&
    cd "$dir"
}

