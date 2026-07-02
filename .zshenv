#!/usr/bin/env zsh
#==============================================================================
#  .zshenv — sourced for EVERY zsh: login, interactive, scripts, `zsh -c`,
#  git hooks, editor-spawned shells. Keep it minimal and subprocess-free.
#
#  Only truly-global environment belongs here. PATH construction and other
#  login-only setup stay in .zprofile; interactive config stays in .zshrc.
#==============================================================================

# Where these dotfiles live. Non-login shells never source .zprofile, so this
# must be here — it replaces the old ": ${DOTFILES:=...}" fallback in .zshrc.
export DOTFILES="$HOME/dotfiles"

# XDG base directories — referenced (with fallbacks) by zinit and the zsh
# completion cache. Set them explicitly so every context resolves the same dirs.
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_STATE_HOME="$HOME/.local/state"

# zsh's own cache dir (compdump + zrecompile output). zreload() in
# functions.zsh relies on this being set; without it compinit -d would try to
# write to /zcomp-$HOST. mkdir guard is a no-op once it exists.
export ZSH_CACHE_DIR="$XDG_CACHE_HOME/zsh"
[[ -d $ZSH_CACHE_DIR ]] || command mkdir -p "$ZSH_CACHE_DIR"

# Locale — needed by scripts and tools, not just interactive shells.
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Preferred programs.
export EDITOR='nvim'
export VISUAL=$EDITOR
export PAGER='less'

# Line-editor word boundaries (base value; .zshrc strips '/' on top of this so
# ^W treats path segments as separate words).
export WORDCHARS='~!#$%^&*(){}[]<>?.+;'
