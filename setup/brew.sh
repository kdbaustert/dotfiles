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
  wifi-password
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
  koekeishiya/formulae/yabai
  khanhas/tap/spicetify-cli
  skhd
  go
  rbenv
  neovim
  selecta
  gitui
  pinentry-mac
  cowsays
  fortune
  figlet
  lolcat
  ccat
  navi
  ffmpeg
  bat
  xxh
  ox
  mdcat
  xplr
  glow
  lsd
  fd
  sqlite
  zlib
  pyenv

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
  vivid
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
  font-jetbrains-mono-nerd-font
  font-monoid-nerd-font
  font-inconsolata
  font-inconsolata-nerd-font
  font-inconsolata-lgc
  font-inconsolata-lgc-nerd-font
)

# Homebrew casks
apps=(
  alfred
  alacritty
  dropbox
  firefox-developer-edition
  brave-browser-beta
  google-chrome
  iterm2-nightly
  slack
  duet
  spotify
  karabiner-elements
  appcleaner
  1password
  captin
  brooklyn
  carbon-copy-cloner
  aerial
  hammerspoon
  bettertouchtool
  visual-studio-code
  insomnia
  github
  little-snitch
  onyx
  keyboard-cleaner
  gitify
  inkdrop
  motrix
  forkLift
  atom-nightly
  malwarebytes
  imazing
  bartender
  archiver
  datagrip
  airbuddy
  raycast
  iina
  yippy
  yt-music
)
