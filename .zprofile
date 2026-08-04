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
export GPG_TTY=$(tty)

# eza / ls colors
export EZA_ICON_SPACING=1
export EZA_GRID_ROWS=5
export EZA_COLUMNS=80
export LSCOLORS=ExFxBxDxCxegedabagacad

#------------------------------------------------------------------------------
# Tooling
#------------------------------------------------------------------------------
export HOMEBREW_BREWFILE="$HOME/.brewfile"
export NTL_RUNNER=yarn
export NVM_COLORS='cmgRY'
export NVM_LAZY_LOAD=true          # zsh-nvm: defer nvm.sh until first node/npm/nvm use
[ -d "$HOME/.nvm" ] && export NVM_DIR="$HOME/.nvm"
export PNPM_HOME="$HOME/Library/pnpm"

#------------------------------------------------------------------------------
# PATH (built once, low → high priority; Homebrew last so it wins)
#------------------------------------------------------------------------------
path=(
  "$HOME/.config/composer/vendor/bin"
  "$HOME/Library/Electron/alias"
  "$HOME/.spicetify"
  "$PNPM_HOME/bin"
  "$HOME/bin"
  "$HOME/.config/phpmon/bin"
  "$HOME/.local/bin"
  "/opt/homebrew/sbin"
  "/opt/homebrew/bin"
  $path
)

# Deduplicate PATH while preserving order
typeset -U path PATH

# Homebrew environment (sets PATH/MANPATH/INFOPATH for the current arch)
eval "$(/opt/homebrew/bin/brew shellenv)"

# Deliberate overrides of a Homebrew formula — must come after `brew shellenv`,
# which re-prepends /opt/homebrew/bin and would otherwise shadow them. This is
# the one exception to "Homebrew wins" above, so it is a dedicated directory
# rather than ~/.local/bin: only what is explicitly placed here outranks brew,
# and dropping a binary into ~/.local/bin later can't quietly do so.
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
