#!/usr/bin/env bash
#==============================================================================
#  dotfiles installer (macOS)
#  Idempotent: safe to re-run. Existing real files are backed up before they
#  are replaced by symlinks; existing symlinks are simply re-pointed.
#==============================================================================

set -uo pipefail

DOTFILES_DIR="${DOTFILES:-$HOME/dotfiles}"

COLOR_GRAY="\033[1;38;5;243m"
COLOR_BLUE="\033[1;34m"
COLOR_GREEN="\033[1;32m"
COLOR_RED="\033[1;31m"
COLOR_PURPLE="\033[1;35m"
COLOR_YELLOW="\033[1;33m"
COLOR_NONE="\033[0m"

title()   { echo -e "\n${COLOR_PURPLE}$1${COLOR_NONE}"; echo -e "${COLOR_GRAY}==============================${COLOR_NONE}\n"; }
error()   { echo -e "${COLOR_RED}Error: ${COLOR_NONE}$1"; exit 1; }
warning() { echo -e "${COLOR_YELLOW}Warning: ${COLOR_NONE}$1"; }
info()    { echo -e "${COLOR_BLUE}Info: ${COLOR_NONE}$1"; }
success() { echo -e "${COLOR_GREEN}$1${COLOR_NONE}"; }

# Symlink helper: $1 = source in repo, $2 = destination in $HOME.
# Skips missing sources, backs up existing real files, replaces symlinks.
link() {
  local src="$1" dst="$2"
  if [ ! -e "$src" ]; then
    warning "Skipping $(basename "$dst") — source missing: $src"
    return
  fi
  if [ -e "$dst" ] && [ ! -L "$dst" ]; then
    mv "$dst" "${dst}.backup-$(date +%Y%m%d-%H%M%S)" && info "Backed up existing $dst"
  fi
  ln -sfn "$src" "$dst" && success "linked  $dst → $src"
}

#------------------------------------------------------------------------------
title "Requesting sudo"
#------------------------------------------------------------------------------
info "Prompting for sudo password..."
if sudo -v; then
  # Keep sudo alive until this script finishes.
  while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
  success "Sudo credentials updated."
else
  error "Failed to obtain sudo credentials."
fi

#------------------------------------------------------------------------------
title "Xcode command line tools"
#------------------------------------------------------------------------------
if xcode-select --print-path &>/dev/null; then
  success "Xcode command line tools already installed."
elif xcode-select --install &>/dev/null; then
  success "Triggered install of Xcode command line tools — finish the GUI prompt, then re-run."
else
  warning "Could not trigger Xcode command line tools install."
fi

#------------------------------------------------------------------------------
title "Homebrew"
#------------------------------------------------------------------------------
if ! command -v brew &>/dev/null; then
  info "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  info "Homebrew already installed — updating & upgrading."
  brew update && brew upgrade
fi

info "Installing dependencies from Brewfile..."
brew bundle install --file="$DOTFILES_DIR/homebrew/Brewfile" || warning "Some Brewfile entries failed (see above)."
brew analytics off
brew cleanup

#------------------------------------------------------------------------------
title "pay-respects"
#------------------------------------------------------------------------------
# Command correction (the `fuck` alias in .zshrc). Not installed via Homebrew:
# there is no formula in core, and the tap the upstream README points at
# (timescam/homebrew-tap) is a 2-star third-party repo owned by someone other
# than the project author that pins `version "nightly"` — a moving target for a
# tool that reads the command line. So: pull the author's own signed release,
# pinned and checksummed, into ~/.local/bin (already on PATH via .zprofile).
#
# The release only ships .tar.zst, which is why this isn't a zinit `gh-r` block
# like starship — zinit's extractor handles zip/tar.gz/tar.xz/7z but not zstd.
#
# arm64 only, matching the aarch64 pin on starship in zsh/zinit.zsh.
# To bump: change PR_VERSION, then update PR_SHA256 from the new asset.
PR_VERSION="0.8.8"
PR_SHA256="e834e928dcaf9cd72a99478bb61e0630ba76e32c7b228eb3a7be9c5f404cd548"
PR_ASSET="pay-respects-${PR_VERSION}-aarch64-apple-darwin.tar.zst"
PR_URL="https://github.com/iffse/pay-respects/releases/download/v${PR_VERSION}/${PR_ASSET}"

if [ "$(uname -m)" != "arm64" ]; then
  warning "Skipping pay-respects — this block is pinned to arm64 (found $(uname -m))."
elif [ -x "$HOME/.local/bin/pay-respects" ] \
  && [ "$("$HOME/.local/bin/pay-respects" --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')" = "$PR_VERSION" ]; then
  info "pay-respects ${PR_VERSION} already installed."
elif ! command -v unzstd &>/dev/null; then
  warning "Skipping pay-respects — unzstd not found (expected from the zstd formula)."
else
  info "Installing pay-respects ${PR_VERSION}..."
  pr_tmp="$(mktemp -d)"
  if curl -sSfL -o "$pr_tmp/$PR_ASSET" "$PR_URL" \
    && echo "${PR_SHA256}  ${pr_tmp}/${PR_ASSET}" | shasum -a 256 -c - >/dev/null 2>&1 \
    && tar --use-compress-program=unzstd -xf "$pr_tmp/$PR_ASSET" -C "$pr_tmp"; then
    mkdir -p "$HOME/.local/bin" "$HOME/.local/share/man/man1" "$HOME/.local/share/man/man5"
    install -m 755 "$pr_tmp/pay-respects" "$HOME/.local/bin/"
    # Rules module only. _pay-respects-fallback-100-request-ai is deliberately
    # NOT installed — it ships failed commands off the machine to an AI endpoint.
    install -m 755 "$pr_tmp/_pay-respects-module-100-runtime-rules" "$HOME/.local/bin/"
    install -m 644 "$pr_tmp"/man/*.1 "$HOME/.local/share/man/man1/" 2>/dev/null
    install -m 644 "$pr_tmp"/man/*.5 "$HOME/.local/share/man/man5/" 2>/dev/null
    success "pay-respects ${PR_VERSION} installed."
  else
    warning "pay-respects install failed (download, checksum, or extract) — skipping."
  fi
  rm -rf "$pr_tmp"
fi

#------------------------------------------------------------------------------
title "Symlinking dotfiles"
#------------------------------------------------------------------------------
# Root-level dotfiles (only those that exist in the repo are linked).
for f in .zshenv .zshrc .vimrc .gitconfig .gitignore .editorconfig .eslintrc .eslintignore \
         .prettierrc .prettierignore .stylelintrc tsconfig.json .default-npm-packages; do
  link "$DOTFILES_DIR/$f" "$HOME/$f"
done

# .zprofile is the zsh login file; also expose it as ~/.profile for parity.
link "$DOTFILES_DIR/.zprofile" "$HOME/.zprofile"
link "$DOTFILES_DIR/.zprofile" "$HOME/.profile"

# ~/.config sub-configs (link every entry that exists in the repo's .config,
# including hidden ones like .claude). dotglob so `*` matches dotfiles too;
# nullglob so an empty dir doesn't leave the literal glob pattern.
mkdir -p "$HOME/.config"
if [ -d "$DOTFILES_DIR/.config" ]; then
  shopt -s dotglob nullglob
  for item in "$DOTFILES_DIR/.config"/*; do
    [ -e "$item" ] || continue
    case "$(basename "$item")" in .DS_Store) continue ;; esac
    link "$item" "$HOME/.config/$(basename "$item")"
  done
  shopt -u dotglob nullglob
fi

#------------------------------------------------------------------------------
title "ClamAV"
#------------------------------------------------------------------------------
# clamav comes from the Brewfile; this wires up config + the signature updater.
# Configs are symlinked (not copied) so edits in the repo take effect directly.
if command -v clamscan &>/dev/null; then
  CLAM_PREFIX="$(brew --prefix)"

  # freshclam refuses to run if these don't exist, and the formula ships none.
  mkdir -p "$CLAM_PREFIX/var/lib/clamav" \
           "$CLAM_PREFIX/var/log/clamav" \
           "$CLAM_PREFIX/var/run/clamav"

  link "$DOTFILES_DIR/clamav/clamd.conf"     "$CLAM_PREFIX/etc/clamav/clamd.conf"
  link "$DOTFILES_DIR/clamav/freshclam.conf" "$CLAM_PREFIX/etc/clamav/freshclam.conf"

  # The configs hard-code /opt/homebrew and the current user; rewrite both if
  # this machine differs (Intel prefix, or a different account name).
  if [ "$CLAM_PREFIX" != "/opt/homebrew" ] || [ "$USER" != "kenny" ]; then
    warning "ClamAV configs are pinned to /opt/homebrew and user 'kenny' — edit clamav/*.conf for this machine."
  fi

  mkdir -p "$HOME/Library/LaunchAgents"
  link "$DOTFILES_DIR/clamav/com.clamav.freshclam.plist" \
       "$HOME/Library/LaunchAgents/com.clamav.freshclam.plist"

  # Signatures aren't in the repo (~120MB, and they'd be stale anyway).
  # This also pulls the third-party DBs declared as DatabaseCustomURL in
  # freshclam.conf (urlhaus, malwarehash, rogue) — see clamav/README.md for
  # why those three and not the others.
  if [ ! -f "$CLAM_PREFIX/var/lib/clamav/daily.cvd" ]; then
    info "Downloading ClamAV signatures (~120MB, takes a minute)..."
    freshclam || warning "freshclam failed — run it manually later."
  else
    info "ClamAV signatures already present — refreshing."
    freshclam || warning "freshclam refresh failed."
  fi

  # A third-party mirror can 404 or move without freshclam failing overall,
  # which would silently leave you with core signatures only. Check explicitly.
  for db in urlhaus.ndb malwarehash.hsb rogue.hdb; do
    if [ ! -s "$CLAM_PREFIX/var/lib/clamav/$db" ]; then
      warning "Third-party signature DB missing: $db — check DatabaseCustomURL in clamav/freshclam.conf"
    fi
  done

  # bootout first so a re-run picks up plist changes; ignore "not loaded".
  launchctl bootout "gui/$(id -u)/com.clamav.freshclam" &>/dev/null
  if launchctl bootstrap "gui/$(id -u)" "$HOME/Library/LaunchAgents/com.clamav.freshclam.plist" 2>/dev/null; then
    success "freshclam updater scheduled (every 2h)."
  else
    warning "Could not load the freshclam LaunchAgent."
  fi

  # Non-sudo: clamd runs as $USER and starts at login, not at boot.
  brew services restart clamav &>/dev/null \
    && success "clamd running." \
    || warning "clamd failed to start — check $CLAM_PREFIX/var/log/clamav/clamd.log"
else
  warning "Skipping ClamAV setup — clamscan not found (Brewfile install may have failed)."
fi

#------------------------------------------------------------------------------
title "Bootstrapping zinit + plugins"
#------------------------------------------------------------------------------
# zinit.zsh self-installs on first interactive shell, but cloning it here keeps
# the very first terminal clean and lets us pre-compile the plugins.
ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
if [ ! -f "$ZINIT_HOME/zinit.zsh" ]; then
  info "Cloning zinit..."
  mkdir -p "$(dirname "$ZINIT_HOME")"
  git clone -q --depth=1 https://github.com/zdharma-continuum/zinit "$ZINIT_HOME" \
    && success "zinit installed." || warning "zinit clone failed — it will retry on first shell."
else
  info "zinit already present."
fi

# Launch a login zsh once so zinit installs the declared plugins. Turbo plugins
# load just after the prompt, so give them a moment, then compile.
if command -v zsh &>/dev/null; then
  info "Installing zsh plugins (first run may take a moment)..."
  zsh -ic 'sleep 3; zinit self-update &>/dev/null; zinit compile --all &>/dev/null; exit' 2>/dev/null \
    && success "Plugins installed & compiled." \
    || warning "Plugin bootstrap incomplete — it finishes on first interactive shell."
fi

### Add Touch ID support for sudo (macOS 10.12.2+)
echo 'auth       sufficient     pam_tid.so' | sudo tee /etc/pam.d/sudo_local >/dev/null
sudo sed -i '' '/pam_tid.so/d' /etc/pam.d/sudo

#------------------------------------------------------------------------------
title "Optional setup scripts"
#------------------------------------------------------------------------------
# Uncomment to run. macos.sh changes system defaults; review before enabling.
# sh "$DOTFILES_DIR/setup/macos.sh"
# sh "$DOTFILES_DIR/setup/npm.sh"
# sh "$DOTFILES_DIR/setup/composer.sh"
# sh "$DOTFILES_DIR/setup/mas.sh"
# sh "$DOTFILES_DIR/setup/gh-extensions.sh"

success "\nDone. Open a new terminal (or run: exec zsh) to load the new shell."
