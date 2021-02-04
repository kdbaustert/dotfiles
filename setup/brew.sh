#! /usr/bin/env sh

# Homebrew taps
brew tap homebrew/cask-fonts
brew tap homebrew/cask-versions
brew tap koekeishiya/formulae

binaries=(
  bash      # Latest Bash version
  coreutils # Those that come with macOS are outdated
  svn
  zsh
  perl
  grep
  openssh
  git
  mackup
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
  go
  rbenv
  neovim
  selecta
  gitui

  # Development
  yarn
  node
  nvm
  php@7.4
  php
  nginx
  php-cs-fixer
  mariadb
  redis
  composer
  wp-cli
  firebase-cli
)

# Homebrew Fonts
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

# Homebrew casks
apps=(
  alfred
  dropbox
  firefox-developer-edition
  brave-browser-nightly
  google-chrome-dev
  microsoft-edge-dev
  vivaldi
  opera-developer
  iterm2-nightly
  hyper-canary
  slack
  spotify
  karabiner-elements
  appcleaner
  1password
  typora
  the-unarchiver
  captin
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
  github
  parallels
  postman
  little-snitch
  onyx
  ios-app-signer
  optimage
  imageoptim
  tor-browser
  keyboard-cleaner
)
