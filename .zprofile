#!/usr/bin/env zsh

#==============================================================================
#  .zprofile — login shell: environment, PATH, locale (no interactive config)
#==============================================================================

#------------------------------------------------------------------------------
# Terminal
#------------------------------------------------------------------------------
# Locale (LANG/LC_ALL), EDITOR, DOTFILES, WORDCHARS and the XDG base dirs now
# live in .zshenv so scripts and non-login shells see them too. TERM is left
# for the terminal to set — iTerm and Rio each advertise their own; hardcoding
# xterm-256color here only risked downgrading Rio's capabilities.
export COLORTERM="truecolor"

#------------------------------------------------------------------------------
# Core (DOTFILES/EDITOR/WORDCHARS/locale/XDG now live in .zshenv)
#------------------------------------------------------------------------------
# $TTY is zsh's own record of the terminal device — same string `tty` prints,
# without the fork+exec. Fall back to tty(1) for the rare login shell that has
# no controlling terminal recorded (non-interactive), where $TTY is unset.
export GPG_TTY="${TTY:-$(tty)}"

# eza / ls colors. LSCOLORS — BSD ls's own variable, which only macOS's /bin/ls
# reads — moved to zsh/os/macos-env.zsh; GNU ls on Arch reads LS_COLORS, which
# vivid generates in .zshrc for eza and the completion menu alike.
export EZA_ICON_SPACING=1
export EZA_GRID_ROWS=5
export EZA_COLUMNS=80

#------------------------------------------------------------------------------
# Tooling
#------------------------------------------------------------------------------
# HOMEBREW_BREWFILE moved to zsh/os/macos-env.zsh with the rest of the Homebrew
# environment — it names this repo's Brewfile for a bare `brew bundle`.
export NTL_RUNNER=pnpm
export NVM_COLORS='cmgRY'
export NVM_LAZY_LOAD=true          # zsh-nvm: defer nvm.sh until first node/npm/nvm use
[ -d "$HOME/.nvm" ] && export NVM_DIR="$HOME/.nvm"

# pnpm's global bin dir, which pnpm itself creates and writes into. The default
# differs by platform and pnpm does not derive it from XDG on macOS: it uses
# ~/Library/pnpm there and $XDG_DATA_HOME/pnpm on Linux. Stated explicitly on
# both rather than left to pnpm, because the path array below has to name it.
if [[ $DOTFILES_OS == macos ]]; then
  export PNPM_HOME="$HOME/Library/pnpm"
else
  export PNPM_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/pnpm"
fi

#------------------------------------------------------------------------------
# PATH (built once, high → low priority: earlier entries win)
#------------------------------------------------------------------------------
# Nix's shell hook, sourced from here rather than from the /etc/zshrc edit its
# installer would make — install.sh passes `--no-modify-profile`, so on a fresh
# machine this is the only wiring. Two reasons it lives in the repo: Apple
# resets /etc/zshrc on major macOS updates, which is the usual way a Nix
# install quietly drops off PATH; and a tracked file is one this repo can see.
#
# Sourced BEFORE the path array on purpose. The hook prepends the Nix profile
# bins, and the array then prepends Homebrew ahead of them, so `brew` still
# wins for any tool installed both ways — the global rule. The /etc hook did
# the opposite: it ran after this file and left ~/.nix-profile/bin at position
# 2 with /opt/homebrew/bin at 9 (measured). The hook exports a guard variable,
# so a machine that still carries the /etc copy sources it once, here, and the
# /etc copy returns immediately.
#
# Cost: tests and exports only, no fork on the common path — 0.16ms per source
# (measured over 200 sourcings), invisible in `zsh -lic exit` — so it does not
# need zcache.
[ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ] \
  && . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh

# Homebrew first, so brew's binaries outrank the language-manager and vendor
# shims below it. (The previous version listed Homebrew *last* under a "Homebrew
# last so it wins" comment — that was backwards for a zsh path array; what
# actually hoisted it was the path_helper call inside `brew shellenv`. Now the
# intended precedence is stated directly by the order of this list.)
#
# The two /opt/homebrew entries are left in this shared array rather than moved
# into zsh/os/macos-env.zsh, even though they mean nothing on Linux: zsh drops a
# PATH entry whose directory does not exist, so they cost a stat apiece there
# and nothing else. Moving them would mean re-prepending from the OS file, which
# would have to land between this array and the ~/.local/overrides block below
# to preserve the precedence both comments describe — a real ordering constraint
# bought for two inert lines.
path=(
  "/opt/homebrew/bin"
  "/opt/homebrew/sbin"
  "$HOME/.config/composer/vendor/bin"
  "$PNPM_HOME/bin"
  "$HOME/.local/bin"
  $path
)

# Deduplicate PATH while preserving order (keeps the first occurrence, so the
# trailing /opt/homebrew/bin that /etc/paths.d contributes collapses into ours)
typeset -U path PATH

# Deliberate overrides of a Homebrew formula — prepended after the array above
# so they outrank /opt/homebrew/bin. This is the one exception to "Homebrew
# wins", so it is a dedicated directory rather than ~/.local/bin: only what is
# explicitly placed here outranks brew, and dropping a binary into ~/.local/bin
# later can't quietly do so.
#
# Currently empty; the directory is kept so an override can be dropped in without
# touching this file.
[ -d "$HOME/.local/overrides" ] && path=("$HOME/.local/overrides" $path) \
  && typeset -U path PATH

#------------------------------------------------------------------------------
# Per-OS login environment
#------------------------------------------------------------------------------
# Everything that exists on ONE platform only: the Homebrew environment and
# FlyEnv's PHP paths on macOS, and (currently) nothing at all on Linux, where
# pacman installs into /usr and both PATH and fpath already cover it.
#
# Paired settings — the same knob with a different value on each platform, like
# PNPM_HOME above — deliberately do NOT live in these files. They stay inline as
# an if/else so the two values sit next to each other and neither can be updated
# without the other being visible. Splitting a pair across two files is how the
# palette drift this repo documents elsewhere starts.
#
# Sourced LAST in this file, which is a real constraint rather than tidiness:
# zsh/os/macos-env.zsh prepends FlyEnv to $path and that has to stay ahead of
# everything the array and the overrides block above install. A file that only
# exported variables could go anywhere; one that touches $path cannot.
[ -r "$DOTFILES/zsh/os/$DOTFILES_OS-env.zsh" ] \
  && source "$DOTFILES/zsh/os/$DOTFILES_OS-env.zsh"
