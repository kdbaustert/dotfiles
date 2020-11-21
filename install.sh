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

# Homebrew taps
brew tap koekeishiya/formulae
brew tap homebrew/cask-versions
brew tap homebrew/cask-fonts

brew update

formulas=(
	svn
	zsh
	perl
	grep
	openssh
	git
	tmux
	z
	openssl
	wget
	neofetch
	diff-so-fancy
	fzf
	git-lfs
	httpie
	jq
	m-cli
	mas
	speedtest-cli
	ssh-copy-id
	terminal-notifier
	wifi-password
	task
	tree
	mycli
	autojump
	gh
	thefuck
	colordiff
	ranger
	htop
	koekeishiya/formulae/yabai
	khanhas/tap/spicetify-cli
	cmacrae/formulae/spacebar
	skhd
	yarn
	node
	go
	rbenv
	composer
	php-cs-fixer
	mariadb
	redis
	wp-cli
	firebase-cli
	neovim
	nginx
	php
	nvm
)

info 'Intalling brew formulas'
info ${formulas[@]}
brew install ${formulas[@]}

fonts=(
	font-fira-code
	font-fira-code-nerd-font
	font-hack-nerd-font
	font-hasklug-nerd-font
	font-jetbrains-mono
	font-jetbrains-mono-nerd-font
	font-mononoki-nerd-font
	font-open-sans
	font-profont-nerd-font
	font-space-mono-nerd-font
	font-ubuntu-mono-nerd-font
	font-ubuntu-nerd-font
	font-jetbrains-mono-nerd-font
)

info 'Intalling brew fonts'
info ${fonts[@]}
brew install ${fonts[@]}

casks=(
	alfred
	dropbox
	firefox-developer-edition
	brave-browser-nightly
	google-chrome-canary
	microsoft-edge-dev
	opera-developer
	iterm2-nightly
	hyper-canary
	terminus
	slack
	spotify
	karabiner-elements
	onyx
	screens
	appcleaner
	1password
	macdown
	the-unarchiver
	expressvpn
	captin
	app-cleaner
	motrix
	brooklyn
	carbon-copy-cloner
	aerial
	hammerspoon
	osxfuse
	bettertouchtool
	zeplin
	sip
	visual-studio-code
	insomnia
	forklift
	datagrip
	github
	parallels
	vim
	postman
)

info 'Intalling brew casks'
info ${casks[@]}
brew install ${casks[@]}

# # NPM Global packages
# . composer.sh

# # Composer Global packages
# . composer.sh

# # Gem gobal packages
# gem install colorls
# gem install istats

# info "Installing Laravel Valet"
# valet composer

# mkdir $HOME/Sites
# mkdir $HOME/Dev

# cd $HOME/Sites

# valet park

# sudo sed -i -e 's/# sudo: auth account password session/# sudo: auth account password session\'$'\nauth       sufficient     pam_tid.so/' /etc/pam.d/sudo
