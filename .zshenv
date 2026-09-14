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

# Which machine this is. Set here rather than in .zprofile because .zshrc,
# aliases.zsh and functions.zsh all branch on it and none of them is guaranteed
# to have seen a login shell — .zshenv is the only file every zsh sources.
#
# A named variable rather than repeating `[[ $OSTYPE == darwin* ]]` at each of
# the dozen-odd branch points: the test is the same every time, and one name
# means a third platform is one line here rather than a grep across the repo.
# $OSTYPE is zsh's own (darwin26.0 / linux-gnu), so this costs no subprocess —
# which is the one rule this file has.
#
# Deliberately NOT a "is this macOS" boolean. The branches read
# `[[ $DOTFILES_OS == macos ]]`, and a value that names the platform makes the
# else-branch obvious to whoever adds the third one. Exported because bash
# scripts under .claude/ read it too, and bash sets $OSTYPE differently enough
# (no version suffix on Linux, but `linux-gnu` either way) that re-deriving it
# there would be a second definition to keep in step.
case $OSTYPE in
  darwin*) export DOTFILES_OS=macos ;;
  linux*)  export DOTFILES_OS=linux ;;
  *)       export DOTFILES_OS=unknown ;;
esac

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

# Fallback model for Claude Code subagents (Task tool) that don't pin their
# own — the built-ins (Explore, general-purpose, Plan) and anything without a
# `model:` in its frontmatter. Custom agents in .claude/agents/ (dotfiles repo)
# set their own tier per task; this just keeps the rest off Opus by default.
# Belongs in .zshenv, not .zprofile: Claude Code spawns subagent processes
# non-interactively, and those only source .zshenv.
export CLAUDE_CODE_SUBAGENT_MODEL='sonnet'

# Line-editor word boundaries (base value; .zshrc strips '/' on top of this so
# ^W treats path segments as separate words).
export WORDCHARS='~!#$%^&*(){}[]<>?.+;'
