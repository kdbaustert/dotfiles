#! /usr/bin/env sh

# Homebrew taps
brew tap homebrew/cask-fonts
brew tap homebrew/cask-versions
brew tap cantino/mcfly
brew tap nicoverbruggen/homebrew-cask
brew tap elastic/tap
brew tap shivammathur/php

binaries=(
	bash      # Latest Bash version
	coreutils # Those that come with macOS are outdated
	svn
	zsh
	perl
	grep
	openssh
	git
	tmux
	gnupg
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
	ssh-copy-id
	terminal-notifier
	task
	fzy
	tree
	mycli
	autojump
	gh
	thefuck
	colordiff
	ranger
	htop
	go
	neovim
	gitui
	pinentry-mac
	fortune
	figlet
	lolcat
	ccat
	navi
	ffmpeg
	bat
	ox
	mdcat
	xplr
	glow
	lsd
	fd
	sqlite
	zlib
	zoxide
	mcfly
	asdf
	git-delta
	exa
	assh
	broot
	procs
	dog
	ripgrep
	nnn
	koekeishiya/formulae/skhd
	koekeishiya/formulae/yabai

	# Development
	nvm
	php
	php@7.4
	nginx
	php-cs-fixer
	mariadb
	redis
	composer
	wp-cli
	firebase-cli
	vivid
	elastic/tap/elasticsearch-full
)

# Homebrew Fonts
fonts=(
	font-fira-code
	font-fira-code-nerd-font
	font-hack-nerd-font
	font-hasklug-nerd-font
	font-hasklig
	font-jetbrains-mono
	font-jetbrains-mono-nerd-font
	font-mononoki-nerd-font
	font-open-sans
	font-profont-nerd-font
	font-space-mono-nerd-font
	font-ubuntu-mono-nerd-font
	font-ubuntu-nerd-font
	font-monoid-nerd-font
	font-inconsolata
	font-inconsolata-nerd-font
	font-inconsolata-lgc
	font-inconsolata-lgc-nerd-font
)

# Homebrew casks
apps=(
	alfred
	dropbox
	firefox-developer-edition
	google-chrome
	iterm2
	slack
	duet
	spotify
	karabiner-elements
	1password
	brooklyn
	carbon-copy-cloner
	aerial
	hammerspoon
	visual-studio-code
	insomnia
	github
	little-snitch
	onyx
	forkLift
	atom-nightly
	imazing
	bartender
	iina
	zeplin
	messenger
	kitty
	optimage
	parallels
	phpmon
	sketch
	protonvpn
	obsidian
	runjs
	tabby
	zoom
	nucleo
	sourcetree-beta
	raycast
	maintenance
	sketch-beta
	gitkraken
	fontplop
	fig
	arctype
)
