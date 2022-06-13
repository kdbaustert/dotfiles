#! /usr/bin/env sh

DOTFILES_DIR=$HOME/dotfiles

COLOR_GRAY="\033[1;38;5;243m"
COLOR_BLUE="\033[1;34m"
COLOR_GREEN="\033[1;32m"
COLOR_RED="\033[1;31m"
COLOR_PURPLE="\033[1;35m"
COLOR_YELLOW="\033[1;33m"
COLOR_NONE="\033[0m"

title() {
  echo -e "\n${COLOR_PURPLE}$1${COLOR_NONE}"
  echo -e "${COLOR_GRAY}==============================${COLOR_NONE}\n"
}

error() {
  echo -e "${COLOR_RED}Error: ${COLOR_NONE}$1"
  exit 1
}

warning() {
  echo -e "${COLOR_YELLOW}Warning: ${COLOR_NONE}$1"
}

info() {
  echo -e "${COLOR_BLUE}Info: ${COLOR_NONE}$1"
}

success() {
  echo -e "${COLOR_GREEN}$1${COLOR_NONE}"
}

info "Prompting for sudo password..."
if sudo -v; then
  # Keep-alive: update existing `sudo` time stamp until `install.sh` has finished
  while true; do
    sudo -n true
    sleep 60
    kill -0 "$$" || exit
  done 2>/dev/null &
  success "Sudo credentials updated."
else
  error "Failed to obtain sudo credentials."
fi

info "Installing XCode command line tools..."
if xcode-select --print-path &>/dev/null; then
  success "XCode command line tools already installed."
elif xcode-select --install &>/dev/null; then
  success "Finished installing XCode command line tools."
else
  error "Failed to install XCode command line tools."
fi

if test ! $(which brew); then
  info 'Installing homebrew...'
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  info 'Homebrew is already installed!'
  info 'Updating homebrew && upgrading all formulas'
  brew update && brew upgrade
fi

DIR=$(dirname "$0")
cd "$DIR"

info "=> Installing dependencies from Brewfile..."
brew bundle --file=$DOTFILES_DIR/homebrew/Brewfile --force
brew analytics off
brew doctor

info "Installing composer packages"
composer global require "${composer[@]}"

info "Creating file symlinks."
ln -sfv "$DOTFILES_DIR/.config/colorls" ~/.config
ln -sfv "$DOTFILES_DIR/.config/dircolors" ~/.config
ln -sfv "$DOTFILES_DIR/.config/colorls" ~/.config
ln -sfv "$DOTFILES_DIR/.config/svgo" ~/.config
ln -sfv "$DOTFILES_DIR/.config/starship.toml" ~/.config
ln -sfv "$DOTFILES_DIR/.config/fish" ~/.config
ln -sfv "$DOTFILES_DIR/.config/lsd" ~/.config

info "Setting chmod for ~/.ssh"
chmod 700 "$HOME/.ssh"

touch "$HOME/.hushlogin"
