#!/usr/bin/env zsh
#==============================================================================
#  autols.zsh — list a directory's contents on entry.
#
#  Hooks chpwd, which covers every kind of directory change: cd, pushd/popd,
#  and zoxide's z/zi (the same reason osc7.zsh hooks chpwd rather than wrapping
#  cd). Deliberately does NOT list the directory the shell starts in — that
#  would add an eza run to every shell startup, and the first prompt is what
#  this repo optimizes hardest. osc7.zsh calls itself once for that case
#  because a stale cwd report is a correctness bug; a missing listing isn't.
#==============================================================================

# Above this many visible entries, print a count instead of the full listing, so
# `cd node_modules` doesn't flood the scrollback on every jump. Override in the
# environment to taste; 0 disables the cap.
: ${AUTO_LS_MAX:=60}

_auto_ls() {
  # Interactive only, and only when stdout is the terminal. -t 1 is what keeps
  # this out of command substitution and out of scripts that happen to cd.
  [[ -o interactive && -t 1 ]] || return 0

  # An unreadable cwd is reachable (cd into a dir whose permissions changed
  # underneath you). Report it plainly rather than letting eza error each time.
  if [[ ! -r $PWD ]]; then
    print -ru2 -- "auto-ls: $PWD is not readable"
    return 0
  fi

  # (N) is nullglob, so an empty directory yields an empty array instead of a
  # "no matches found" error. Dotfiles are excluded to match what the listing
  # below actually shows — eza hides them without -a, so counting them would
  # make the cap fire on directories that look nearly empty.
  local -a entries=(*(N))

  (( $#entries )) || return 0   # empty directory: stay quiet

  if (( AUTO_LS_MAX > 0 && $#entries > AUTO_LS_MAX )); then
    print -r -- "auto-ls: $#entries entries (> \$AUTO_LS_MAX=$AUTO_LS_MAX), listing skipped"
    return 0
  fi

  # eza is called directly, not through the `ls` alias: aliases are expanded
  # when a function is *parsed*, so depending on aliases.zsh having loaded first
  # would make this silently brittle. Flags mirror that alias plus the
  # --group-directories-first used by l1/le.
  if (( $+commands[eza] )); then
    eza --icons --classify --group-directories-first
  else
    command ls -F
  fi
}

if [[ -o interactive ]]; then
  autoload -Uz add-zsh-hook
  add-zsh-hook chpwd _auto_ls
fi
