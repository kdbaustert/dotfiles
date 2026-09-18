#!/usr/bin/env zsh
#==============================================================================
#  zsh/os/macos-env.zsh — login environment that exists only on macOS
#------------------------------------------------------------------------------
#  Sourced from the end of .zprofile via $DOTFILES_OS (set in .zshenv). Login
#  shells only: this is PATH and environment, not interactive config — the
#  aliases and the command-not-found handler are in macos-interactive.zsh.
#
#  The rule for what belongs here: a setting with no counterpart on the other
#  platform. A setting that exists on both with a different value stays inline
#  in .zprofile as an if/else, so the pair is visible in one place.
#==============================================================================

#------------------------------------------------------------------------------
# Homebrew environment
#------------------------------------------------------------------------------
# This is what `eval "$(brew shellenv)"` used to do, written out literally.
#
# `brew shellenv` costs ~10ms — by far the most expensive thing in shell
# startup — and almost all of that is the `/usr/libexec/path_helper` subprocess
# it evals. That call was pure redundancy here: macOS's /etc/zprofile ALREADY
# runs path_helper before .zprofile is sourced, so every /etc/paths.d entry
# (homebrew, cryptex, rvictl, Little Snitch, VMware Fusion) is in $path by the
# time we get here. Brew's second call only *reordered* what was already there,
# hoisting /opt/homebrew/{bin,sbin} to the front — which the explicit path
# array in .zprofile now does directly, and visibly.
#
# The values are stable for a given prefix; `brew --prefix` is /opt/homebrew on
# Apple Silicon and does not move. Nothing here needs to run brew to find out.
# Points a bare `brew bundle` (no --file) at this repo's list; install.sh passes
# the path explicitly and does not rely on it.
export HOMEBREW_BREWFILE="${DOTFILES:-$HOME/dotfiles}/homebrew/Brewfile"

export HOMEBREW_PREFIX="/opt/homebrew"
export HOMEBREW_CELLAR="/opt/homebrew/Cellar"
export HOMEBREW_REPOSITORY="/opt/homebrew"
export INFOPATH="/opt/homebrew/share/info:${INFOPATH:-}"

# Completions shipped by Homebrew formulae. compinit (run from zinit's turbo
# block in .zshrc) picks these up from fpath.
#
# The Linux side needs no twin: Arch packages drop their completions into
# /usr/share/zsh/site-functions, which is on zsh's default fpath already.
fpath=("/opt/homebrew/share/zsh/site-functions" $fpath)

# NB: brew shellenv also exported MANPATH. That is deliberately dropped — it is
# actively worse than leaving it unset. path_helper builds MANPATH from
# /etc/manpaths only, which does NOT include /opt/homebrew/share/man; with
# MANPATH unset, `man` falls back to its own manpath(1) logic, which derives man
# directories from $PATH and so *does* find Homebrew's (plus ~/.local/share/man
# and Xcode's). Verified: `man -w eza` resolves either way, but `manpath` returns
# a strictly larger, more correct list with MANPATH unset.

# LSCOLORS is BSD ls's colour string — a different variable and a different
# format from the LS_COLORS that vivid generates in .zshrc for eza and the
# completion menu. Only macOS's /bin/ls reads it, which is why it sits here
# rather than beside its GNU-shaped namesake.
export LSCOLORS=ExFxBxDxCxegedabagacad

#------------------------------------------------------------------------------
# Xcode toolchain (sourcekit-lsp)
#------------------------------------------------------------------------------
# Puts sourcekit-lsp — the Swift language server — on PATH. It ships inside
# Xcode's toolchain and nowhere else, which is what makes this a macos-env.zsh
# entry rather than something portable.
#
# Written out literally rather than `export PATH="$(dirname $(xcrun --find
# sourcekit-lsp)):$PATH"`, which is how this arrived, for exactly the reason
# the Homebrew block above is written out: that is two subprocesses on the
# login path, measured at ~11ms together, to print a directory that only moves
# when Xcode does. The `xcrun` fallback below covers the cases the literal
# cannot — Xcode installed somewhere other than /Applications, or only the
# Command Line Tools — and costs nothing when the literal path is there.
#
# Prepended BEFORE the FlyEnv block rather than after, deliberately. This
# directory holds the whole toolchain — swift, swiftc, clang, lldb — not just
# the language server, so where it lands decides which compiler wins. Going in
# first leaves FlyEnv's prepend last, which is the guarantee the section below
# documents and depends on.
_xcode_toolchain_bin="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin"
if [ ! -d "$_xcode_toolchain_bin" ] && (( $+commands[xcrun] )); then
  _xcode_toolchain_bin=${${:-$(xcrun --find sourcekit-lsp 2>/dev/null)}:h}
fi
[ -d "$_xcode_toolchain_bin" ] && path=(
  "$_xcode_toolchain_bin"
  $path
) && typeset -U path PATH
unset _xcode_toolchain_bin

#------------------------------------------------------------------------------
# FlyEnv
#------------------------------------------------------------------------------
# FlyEnv (PHP dev-environment manager) — prepended last so its PHP wins over
# Homebrew's, preserving the previous behavior when this lived at the end of
# .zshrc. Guarded so it's a no-op when FlyEnv isn't installed; a not-yet-created
# subdir in the list is harmless (zsh just skips missing PATH entries).
#
# This prepend is why .zprofile sources this file at the very end. Moving the
# source line earlier would put FlyEnv's PHP behind Homebrew's and silently
# change which `php` runs.
[ -d "$HOME/Library/FlyEnv" ] && path=(
  "$HOME/Library/FlyEnv/alias"
  "$HOME/Library/FlyEnv/env/php/bin"
  "$HOME/Library/FlyEnv/env/php"
  $path
) && typeset -U path PATH
