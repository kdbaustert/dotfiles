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

# eza / ls colors
export EZA_ICON_SPACING=1
export EZA_GRID_ROWS=5
export EZA_COLUMNS=80
export LSCOLORS=ExFxBxDxCxegedabagacad

#------------------------------------------------------------------------------
# Tooling
#------------------------------------------------------------------------------
export HOMEBREW_BREWFILE="${DOTFILES:-$HOME/dotfiles}/homebrew/Brewfile"
export NTL_RUNNER=pnpm
export NVM_COLORS='cmgRY'
export NVM_LAZY_LOAD=true          # zsh-nvm: defer nvm.sh until first node/npm/nvm use
[ -d "$HOME/.nvm" ] && export NVM_DIR="$HOME/.nvm"
export PNPM_HOME="$HOME/Library/pnpm"

#------------------------------------------------------------------------------
# Homebrew environment
#------------------------------------------------------------------------------
# This is what `eval "$(brew shellenv)"` used to do, written out literally.
#
# `brew shellenv` costs ~10ms — by far the most expensive thing in shell
# startup — and almost all of that is the `/usr/libexec/path_helper` subprocess
# it evals. That call was pure redundancy here: macOS's /etc/zprofile ALREADY
# runs path_helper before this file is sourced, so every /etc/paths.d entry
# (homebrew, cryptex, rvictl, Little Snitch, VMware Fusion) is in $path by the
# time we get here. Brew's second call only *reordered* what was already there,
# hoisting /opt/homebrew/{bin,sbin} to the front — which the explicit path
# array below now does directly, and visibly.
#
# The values are stable for a given prefix; `brew --prefix` is /opt/homebrew on
# Apple Silicon and does not move. Nothing here needs to run brew to find out.
export HOMEBREW_PREFIX="/opt/homebrew"
export HOMEBREW_CELLAR="/opt/homebrew/Cellar"
export HOMEBREW_REPOSITORY="/opt/homebrew"
export INFOPATH="/opt/homebrew/share/info:${INFOPATH:-}"

# Completions shipped by Homebrew formulae. compinit (run from zinit's turbo
# block in .zshrc) picks these up from fpath.
fpath=("/opt/homebrew/share/zsh/site-functions" $fpath)

# NB: brew shellenv also exported MANPATH. That is deliberately dropped — it is
# actively worse than leaving it unset. path_helper builds MANPATH from
# /etc/manpaths only, which does NOT include /opt/homebrew/share/man; with
# MANPATH unset, `man` falls back to its own manpath(1) logic, which derives man
# directories from $PATH and so *does* find Homebrew's (plus ~/.local/share/man
# and Xcode's). Verified: `man -w eza` resolves either way, but `manpath` returns
# a strictly larger, more correct list with MANPATH unset.

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

# FlyEnv (PHP dev-environment manager) — prepended last so its PHP wins over
# Homebrew's, preserving the previous behavior when this lived at the end of
# .zshrc. Guarded so it's a no-op when FlyEnv isn't installed; a not-yet-created
# subdir in the list is harmless (zsh just skips missing PATH entries).
[ -d "$HOME/Library/FlyEnv" ] && path=(
  "$HOME/Library/FlyEnv/alias"
  "$HOME/Library/FlyEnv/env/php/bin"
  "$HOME/Library/FlyEnv/env/php"
  $path
) && typeset -U path PATH
