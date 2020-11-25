#! /usr/bin/env sh

# Homebrew taps
taps=(
  homebrew/cask-fonts
  homebrew/cask-versions
  koekeishiya/formulae
)

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
  zlib # Needed for Memcached
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
  pwgen
  koekeishiya/formulae/yabai
  khanhas/tap/spicetify-cli
  cmacrae/formulae/spacebar
  skhd
  go
  rbenv
  neovim

  # Development
  yarn
  node
  nvm
  php@7.2
  php@7.3
  php@7.4
  nginx
  php
  php-cs-fixer
  mariadb
  memcached
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
  opera-developer
  iterm2-nightly
  hyper-canary
  terminus
  slack
  spotify
  karabiner-elements
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
  postman
)
