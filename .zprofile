#!/usr/bin/env zsh
#==============================================================================
#  .zprofile — login shell: environment, PATH, locale (no interactive config)
#==============================================================================

# Kiro CLI pre block. Keep at the top of this file.
[[ -f "${HOME}/Library/Application Support/kiro-cli/shell/zprofile.pre.zsh" ]] && builtin source "${HOME}/Library/Application Support/kiro-cli/shell/zprofile.pre.zsh"

#------------------------------------------------------------------------------
# Locale & terminal
#------------------------------------------------------------------------------
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export COLORTERM="truecolor"
export TERM="xterm-256color"

#------------------------------------------------------------------------------
# Core
#------------------------------------------------------------------------------
export DOTFILES="$HOME/dotfiles"
export EDITOR='nvim'
export VISUAL=$EDITOR
export GPG_TTY=$(tty)
export WORDCHARS='~!#$%^&*(){}[]<>?.+;'

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
export PYENV_ROOT="$HOME/.pyenv"
export PNPM_HOME="$HOME/Library/pnpm"

#------------------------------------------------------------------------------
# PATH (built once, low → high priority; Homebrew last so it wins)
#------------------------------------------------------------------------------
path=(
  "$HOME/.config/composer/vendor/bin"
  "$HOME/Library/Electron/alias"
  "$HOME/.spicetify"
  "$PNPM_HOME"
  "$HOME/bin"
  "$HOME/.config/phpmon/bin"
  "$PYENV_ROOT/bin"
  "$HOME/.local/bin"
  "/opt/homebrew/sbin"
  "/opt/homebrew/bin"
  $path
)

# PhpWebStudy (only if installed)
[ -d "$HOME/Library/PhpWebStudy/alias" ] && path=(
  "$HOME/Library/PhpWebStudy/alias"
  "$HOME/Library/PhpWebStudy/env/php"
  "$HOME/Library/PhpWebStudy/env/php/bin"
  $path
)

# Deduplicate PATH while preserving order
typeset -U path PATH

# Homebrew environment (sets PATH/MANPATH/INFOPATH for the current arch)
eval "$(/opt/homebrew/bin/brew shellenv)"

# pyenv shims, prepended last so they win over Homebrew's python. This is the
# only pyenv work done synchronously (no subprocess); the rest of pyenv's shell
# integration is loaded via zinit turbo (see zsh/zinit.zsh).
[ -d "$PYENV_ROOT/shims" ] && path=("$PYENV_ROOT/shims" $path) && typeset -U path PATH

# Kiro CLI post block. Keep at the bottom of this file.
[[ -f "${HOME}/Library/Application Support/kiro-cli/shell/zprofile.post.zsh" ]] && builtin source "${HOME}/Library/Application Support/kiro-cli/shell/zprofile.post.zsh"
