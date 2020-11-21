#! /usr/bin/env sh

DIR=$(dirname "$0")
cd "$DIR"

. scripts/functions.sh

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

# Check for Homebrew
if test ! $(which brew); then
	info 'Installing homebrew...'
	ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
else
	info 'Homebrew is already installed!'
	info 'Updating homebrew && upgrading all formulas'
	brew update && brew upgrade
fi

# Homebrew packages
. /setup/brew.sh

# Composer Global packages
. /setup/composer.sh

# NPM Global packages
. /setup/npm.sh

# Gem gobal packages
gem install colorls
gem install istats

info "Installing Laravel Valet"
valet composer

mkdir $HOME/Sites
mkdir $HOME/Dev

cd $HOME/Sites

valet park
