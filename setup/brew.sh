#! /usr/bin/env sh

# Homebrew taps
taps=(
  homebrew/cask-fonts
  homebrew/cask-versions
  koekeishiya/formulae
)

info ${taps[@]}
brew install ${taps[@]}

brew update

# Homebrew Packages
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
brew install ${formulas[@]}

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

info 'Intalling brew fonts'
info ${fonts[@]}
brew install ${fonts[@]}

# Homebrew casks
apps=(
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

info 'Intalling brew applications'
brew install ${casks[@]}
