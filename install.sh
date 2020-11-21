#! /usr/bin/env sh

DIR=$(dirname "$0")
cd "$DIR"

. scripts/functions.sh
. setup/brew.sh
. setup/composer.sh
. setup/npm.sh

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

info ${taps[@]}
brew install ${taps[@]}

brew update

info 'Intalling brew fonts'
info ${fonts[@]}
brew install ${fonts[@]}

info 'Intalling brew formulas'
brew install ${formulas[@]}

info 'Intalling brew applications'
brew install ${casks[@]}

# Composer Global packages
info "Installing composer global packages."
info ${composer[@]}
composer global require ${composer[@]}

# NPM Global packages
info "Installing npm global packages."
info ${npm[@]}
npm install -g ${npm[@]}

# Gem gobal packages
gem install colorls
gem install istats

info "Installing Laravel Valet"
valet composer

mkdir $HOME/Sites
mkdir $HOME/Dev

cd $HOME/Sites

valet park
