#!/usr/bin/env bash
#==============================================================================
#  dotfiles installer (macOS)
#  Idempotent: safe to re-run. Existing real files are backed up before they
#  are replaced by symlinks; existing symlinks are simply re-pointed.
#==============================================================================

set -uo pipefail

DOTFILES_DIR="${DOTFILES:-$HOME/dotfiles}"

COLOR_GRAY="\033[1;38;5;243m"
COLOR_BLUE="\033[1;34m"
COLOR_GREEN="\033[1;32m"
COLOR_RED="\033[1;31m"
COLOR_PURPLE="\033[1;35m"
COLOR_YELLOW="\033[1;33m"
COLOR_NONE="\033[0m"

title()   { echo -e "\n${COLOR_PURPLE}$1${COLOR_NONE}"; echo -e "${COLOR_GRAY}==============================${COLOR_NONE}\n"; }
error()   { echo -e "${COLOR_RED}Error: ${COLOR_NONE}$1"; exit 1; }
warning() { echo -e "${COLOR_YELLOW}Warning: ${COLOR_NONE}$1"; }
info()    { echo -e "${COLOR_BLUE}Info: ${COLOR_NONE}$1"; }
success() { echo -e "${COLOR_GREEN}$1${COLOR_NONE}"; }

# Symlink helper: $1 = source in repo, $2 = destination in $HOME.
# Skips missing sources, backs up existing real files, replaces symlinks.
link() {
  local src="$1" dst="$2"
  if [ ! -e "$src" ]; then
    warning "Skipping $(basename "$dst") — source missing: $src"
    return
  fi
  if [ -e "$dst" ] && [ ! -L "$dst" ]; then
    mv "$dst" "${dst}.backup-$(date +%Y%m%d-%H%M%S)" && info "Backed up existing $dst"
  fi
  ln -sfn "$src" "$dst" && success "linked  $dst → $src"
}

#------------------------------------------------------------------------------
title "Requesting sudo"
#------------------------------------------------------------------------------
info "Prompting for sudo password..."
if sudo -v; then
  # Keep sudo alive until this script finishes.
  while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
  success "Sudo credentials updated."
else
  error "Failed to obtain sudo credentials."
fi

#------------------------------------------------------------------------------
title "Xcode command line tools"
#------------------------------------------------------------------------------
if xcode-select --print-path &>/dev/null; then
  success "Xcode command line tools already installed."
elif xcode-select --install &>/dev/null; then
  success "Triggered install of Xcode command line tools — finish the GUI prompt, then re-run."
else
  warning "Could not trigger Xcode command line tools install."
fi

#------------------------------------------------------------------------------
title "Homebrew"
#------------------------------------------------------------------------------
if ! command -v brew &>/dev/null; then
  info "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  info "Homebrew already installed — updating & upgrading."
  brew update && brew upgrade
fi

info "Installing dependencies from Brewfile..."
brew bundle install --file="$DOTFILES_DIR/homebrew/Brewfile" || warning "Some Brewfile entries failed (see above)."
brew analytics off
brew cleanup

#------------------------------------------------------------------------------
title "Symlinking dotfiles"
#------------------------------------------------------------------------------
# Root-level dotfiles (only those that exist in the repo are linked).
for f in .zshrc .gitconfig .gitignore .editorconfig .eslintrc .eslintignore \
         .prettierrc .prettierignore .stylelintrc tsconfig.json .default-npm-packages; do
  link "$DOTFILES_DIR/$f" "$HOME/$f"
done

# .zprofile is the zsh login file; also expose it as ~/.profile for parity.
link "$DOTFILES_DIR/.zprofile" "$HOME/.zprofile"
link "$DOTFILES_DIR/.zprofile" "$HOME/.profile"

# ~/.config sub-configs (link every entry that exists in the repo's .config).
mkdir -p "$HOME/.config"
if [ -d "$DOTFILES_DIR/.config" ]; then
  for item in "$DOTFILES_DIR/.config"/*; do
    [ -e "$item" ] || continue
    case "$(basename "$item")" in .DS_Store) continue ;; esac
    link "$item" "$HOME/.config/$(basename "$item")"
  done
fi

#------------------------------------------------------------------------------
title "Bootstrapping zinit + plugins"
#------------------------------------------------------------------------------
# zinit.zsh self-installs on first interactive shell, but cloning it here keeps
# the very first terminal clean and lets us pre-compile the plugins.
ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
if [ ! -f "$ZINIT_HOME/zinit.zsh" ]; then
  info "Cloning zinit..."
  mkdir -p "$(dirname "$ZINIT_HOME")"
  git clone -q --depth=1 https://github.com/zdharma-continuum/zinit "$ZINIT_HOME" \
    && success "zinit installed." || warning "zinit clone failed — it will retry on first shell."
else
  info "zinit already present."
fi

# Launch a login zsh once so zinit installs the declared plugins. Turbo plugins
# load just after the prompt, so give them a moment, then compile.
if command -v zsh &>/dev/null; then
  info "Installing zsh plugins (first run may take a moment)..."
  zsh -ic 'sleep 3; zinit self-update &>/dev/null; zinit compile --all &>/dev/null; exit' 2>/dev/null \
    && success "Plugins installed & compiled." \
    || warning "Plugin bootstrap incomplete — it finishes on first interactive shell."
fi

#------------------------------------------------------------------------------
title "Optional setup scripts"
#------------------------------------------------------------------------------
# Uncomment to run. macos.sh changes system defaults; review before enabling.
# sh "$DOTFILES_DIR/setup/macos.sh"
# sh "$DOTFILES_DIR/setup/npm.sh"
# sh "$DOTFILES_DIR/setup/composer.sh"
# sh "$DOTFILES_DIR/setup/mas.sh"
# sh "$DOTFILES_DIR/setup/gh-extensions.sh"

success "\nDone. Open a new terminal (or run: exec zsh) to load the new shell."
