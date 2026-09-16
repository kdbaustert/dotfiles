# NixOS package list — the Nix equivalent of homebrew/Brewfile and
# arch/pkglist. Not wired into install.sh/install-linux.sh yet — neither
# installer targets NixOS, so this is a standalone `environment.systemPackages`
# fragment to `import` from a NixOS `configuration.nix`, e.g.:
#
#   environment.systemPackages = import ./setup/nixos-packages.nix pkgs;
#
# NOT VERIFIED AGAINST A LIVE NIXOS CHANNEL. Names are nixpkgs' as best known
# from package search, transcribed from the Brewfile the same way arch/pkglist
# was transcribed from it — see that file's header for the same caveat. Run
# `nix-env -qaP <name>` (or check search.nixos.org) before trusting one you
# haven't installed before.
#
# Only CLI/server packages are translated — the 90 macOS casks are GUI apps and
# picking Linux/NixOS equivalents is a per-app decision, not a mapping, exactly
# as arch/pkglist says for the same list. Fonts are the one cask category
# translated, since .config/ghostty/config and .config/rio/config.toml name
# specific font families that need to exist on any platform running them.
#
# Packages fetched by zinit as gh-r binaries on macOS (bat, lsd, fd, zoxide,
# git-delta, ripgrep, fzf, vivid, atuin — see zsh/zinit.zsh section 5, and the
# commented-out `brew` lines in homebrew/Brewfile) are listed here anyway,
# same as they are in arch/pkglist: a NixOS box has no zinit gh-r fetch step,
# so these need to come from nixpkgs instead.

pkgs:
with pkgs;
[
  # --- Shell and core ---------------------------------------------------------
  zsh
  bash
  coreutils
  gnugrep
  perl
  openssh
  git
  git-lfs
  subversion # svn
  tmux
  gnupg
  openssl
  wget
  curl
  rsync
  man-db
  man-pages
  utillinux

  # --- The tools .zshrc and CLAUDE.md actually name ---------------------------
  ripgrep
  fd
  fzf
  jq
  bat
  eza
  lsd
  zoxide
  atuin
  starship
  delta # git-delta
  lazygit
  gitui
  procs
  navi
  vivid
  direnv
  neovim
  helix
  yazi
  btop
  htop
  glow
  xplr
  nnn
  ranger
  fastfetch
  tree
  zstd
  p7zip # sevenzip / 7zip
  imagemagick
  ffmpeg
  poppler_utils # poppler
  sqlite
  nss
  figlet
  fortune
  lolcat
  colordiff
  httpie
  taskwarrior-tui
  fzy

  # --- Extra CLI tools present in the Brewfile but not in arch/pkglist --------
  gh
  mas # no NixOS equivalent (App Store), kept for parity — likely unused
  m-cli # macOS-only, no NixOS equivalent — likely unused
  ssh-copy-id # part of openssh, listed for parity with the Brewfile
  terminal-notifier # macOS-only, no NixOS equivalent — likely unused
  mycli
  carapace
  ranger
  go
  pinentry # pinentry-mac is macOS-only; pinentry is the portable equivalent
  ccat
  ox
  mdcat
  nodejs
  nodePackages.pnpm # pnpm
  shellcheck
  shfmt
  stylua
  php
  nginx
  php-cs-fixer
  mariadb
  redis
  composer
  zig
  python3
  python3Packages.pip

  # --- Notifications -----------------------------------------------------------
  # libnotify provides notify-send, used the same way arch/pkglist documents it.
  libnotify

  # --- Clipboard -----------------------------------------------------------
  # Both, for the same reason arch/pkglist installs both: the session type
  # (Wayland vs. X11) determines which one actually works.
  wl-clipboard
  xclip
  xdg-utils

  # --- Fonts -----------------------------------------------------------------
  # Nerd Fonts v3, matching what .config/ghostty/config and
  # .config/rio/config.toml name — see arch/pkglist's font section for the
  # same v2/v3 note (applies to the tab-icon font build, not these).
  nerd-fonts.hack
  nerd-fonts.jetbrains-mono
  nerd-fonts.fira-code
  nerd-fonts.sauce-code-pro
  nerd-fonts.roboto-mono
  nerd-fonts.symbols-only
  fira-code
  noto-fonts
  noto-fonts-emoji
]
