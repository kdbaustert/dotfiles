#! /usr/bin/env sh

DIR=$(dirname "$0")
cd "$DIR"

. scripts/functions.sh
. setup/brew.sh
. setup/composer.sh
. setup/npm.sh

# Homebrew Applications
info 'Intalling brew applications'
brew install ${apps[@]}

# Setup Symlinks
info "Creating file symlinks."
ln -s "$HOME/dotfiles/.zshrc" $HOME/
ln -s "$HOME/dotfiles/skhd/.skhdrc" $HOME/
ln -s "$HOME/dotfiles/yabai/.yabairc" $HOME/
ln -s "$HOME/dotfiles/spacebar/.spacebarrc" $HOME/
ln -s "$HOME/dotfiles/neofetch/config.conf" "$HOME/.config/neofetch"
ln -s "$HOME/dotfiles/.mackup.cfg" $HOME/

info "Setting chmod for ~/.ssh"
chmod 700 "$HOME/.ssh"

# Gem gobal packages
gem install colorls

info "Installing Laravel Valet"
valet composer

mkdir "$HOME/Sites"
mkdir "$HOME/Dev"

cd "$HOME/Sites"

valet park

# Global ignore
git config --global core.excludesFile "$HOME/.gitignore"

# Setup git user config
git config --global user.name "Kenny Baustert"
git config --global user.email "kenny@gothamx.dev"

touch "$HOME/.hushlogin"
