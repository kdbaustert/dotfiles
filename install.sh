#!/usr/bin/env bash
#==============================================================================
#  dotfiles installer (macOS)
#  Idempotent: safe to re-run. Existing real files are backed up before they
#  are replaced by symlinks; existing symlinks are simply re-pointed.
#==============================================================================

set -uo pipefail

DOTFILES_DIR="${DOTFILES:-$HOME/dotfiles}"

# The print helpers, link(), and every section that is identical on Arch —
# symlinking, zinit, the theme caches, LS_COLORS, pay-respects, the setup-script
# runner. install-linux.sh sources the same file, which is the point: the
# symlink section changes every time a skill or a .config entry is added, and
# two copies of it would drift silently. See setup/lib.sh's header.
# shellcheck source=setup/lib.sh
source "$DOTFILES_DIR/setup/lib.sh"

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
title "Nix"
#------------------------------------------------------------------------------
# The Nix package manager, beside Homebrew rather than instead of it. The split:
# Homebrew owns the machine — the Brewfile, casks, fonts, the global CLI set —
# and Nix owns per-project environments. `nix-shell` and `nix develop` give a
# repo a pinned toolchain without touching anything global, which Homebrew has
# no equivalent for. Don't install through Nix what the Brewfile already has:
# both ship ripgrep, fd, jq, bat, eza, fzf, zoxide, starship, atuin, git,
# delta, lazygit, neovim, node and python, and a second copy only drifts.
#
# Upstream's installer, not Determinate Systems'. Determinate's writes a
# receipt for a clean uninstall and re-adds its /etc/zshrc hook after a macOS
# upgrade, but it puts a third party between us and the interpreter, and this
# machine was first installed with upstream. The one thing it fixes — the /etc
# hook — is moot here: `--no-modify-profile` skips that edit entirely and
# .zprofile sources the hook itself, tracked and upgrade-proof (Apple resets
# /etc/zshrc on major updates, which is the usual way a Nix install quietly
# drops off PATH).
#
# `--daemon` is the only mode macOS accepts — the installer refuses
# `--no-daemon` on Darwin — and it creates a separate APFS volume for /nix,
# since the root volume is read-only. The default nixpkgs-unstable channel is
# kept: `nix-shell -p` resolves <nixpkgs> through it, and without a channel
# that form fails until flakes are set up.
#
# Guarded on the binary, not on /nix: a half-finished install leaves the
# directory behind and the installer refuses to run over one, so a stale /nix
# surfaces here as the warning below with the installer's own message above it.
NIX_BIN="/nix/var/nix/profiles/default/bin/nix"
if [ -x "$NIX_BIN" ]; then
  info "Nix already installed ($("$NIX_BIN" --version))."
else
  info "Installing Nix (multi-user daemon — this creates a /nix APFS volume)..."
  if sh <(curl -fsSL https://nixos.org/nix/install) --daemon --yes --no-modify-profile \
    && [ -x "$NIX_BIN" ]; then
    success "Nix installed ($("$NIX_BIN" --version))."
  else
    warning "Nix install failed — see the installer output above; nix-shell stays unavailable."
  fi
fi

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
# arm64 only, matching the aarch64 pin on starship in zsh/zinit.zsh. The
# install itself is shared — see install_pay_respects in setup/lib.sh; only the
# asset name and its checksum are platform-specific, which is why they are
# arguments rather than something the library guesses from `uname`.
# To bump: change PR_VERSION, then update PR_SHA256 from the new asset.
PR_VERSION="0.8.8"
PR_SHA256="e834e928dcaf9cd72a99478bb61e0630ba76e32c7b228eb3a7be9c5f404cd548"

if [ "$(uname -m)" != "arm64" ]; then
  warning "Skipping pay-respects — this block is pinned to arm64 (found $(uname -m))."
else
  install_pay_respects "$PR_VERSION" "$PR_SHA256" \
    "pay-respects-${PR_VERSION}-aarch64-apple-darwin.tar.zst"
fi

#------------------------------------------------------------------------------
title "LS_COLORS (trapd00r)"
#------------------------------------------------------------------------------
# The second LS_COLORS database, alongside the vivid/Voltage one that .zshrc
# defaults to. Why it is a clone rather than a release, and why it is not a
# zinit plugin, is in setup/lib.sh — identical on both platforms, so the
# reasoning lives with the code rather than being copied into two installers.
install_ls_colors

#------------------------------------------------------------------------------
title "Symlinking dotfiles"
#------------------------------------------------------------------------------
# Every symlink lives in setup/lib.sh so install-linux.sh deploys exactly the
# same set. `macos` selects which .gitconfig-os half is linked — the one setting
# git cannot branch on at runtime.
link_dotfiles macos

#------------------------------------------------------------------------------
title "Bootstrapping zinit + plugins"
#------------------------------------------------------------------------------
bootstrap_zinit

#------------------------------------------------------------------------------
title "Theme (Voltage)"
#------------------------------------------------------------------------------
build_themes

#------------------------------------------------------------------------------
title "Tab icon font"
#------------------------------------------------------------------------------
# fonts/HackNerdFontColor-Regular.ttf is Hack Nerd Font with a COLR/CPAL table
# added, so the tab icons zsh/extra/tabtitle.zsh emits come out in iTerm2's
# tints. .config/ghostty/config names it as window-title-font-family; it does
# not replace the terminal font, and the two families coexist.
#
# COPIED, not linked, unlike everything else here: CoreText does not register a
# symlinked font out of ~/Library/Fonts. Measured — a real copy resolved through
# NSFont within ~3s while the symlink stayed invisible through 24s of polling,
# even though fc-list listed it the whole time. So a font edit in the repo needs
# this step re-run; the cmp guard makes that cheap.
TAB_ICON_FONT="$DOTFILES_DIR/fonts/HackNerdFontColor-Regular.ttf"
TAB_ICON_DEST="$HOME/Library/Fonts/HackNerdFontColor-Regular.ttf"
if [ ! -f "$TAB_ICON_FONT" ]; then
  warning "Skipping tab icon font — not built: $TAB_ICON_FONT"
elif cmp -s "$TAB_ICON_FONT" "$TAB_ICON_DEST"; then
  info "Tab icon font already current."
else
  mkdir -p "$HOME/Library/Fonts"
  if cp "$TAB_ICON_FONT" "$TAB_ICON_DEST"; then
    success "installed $TAB_ICON_DEST"
  else
    warning "Could not install the tab icon font; tab icons stay monochrome."
  fi
fi

#------------------------------------------------------------------------------
title "Touch ID for sudo"
#------------------------------------------------------------------------------
# /etc/pam.d/sudo_local is Apple's supported override file (macOS 14+); it is
# `include`d by /etc/pam.d/sudo and, unlike that file, survives OS updates.
#
# Both operations below are now guarded. They used to run unconditionally on
# every invocation, outside any section heading, which meant a re-run silently
# rewrote a root-owned PAM file and ran a destructive sed over Apple's own
# /etc/pam.d/sudo — with no output either way. A mistake there costs you sudo.
PAM_TID='auth       sufficient     pam_tid.so'

if [ -f /etc/pam.d/sudo_local ] && grep -q '^[^#]*pam_tid\.so' /etc/pam.d/sudo_local; then
  info "Touch ID for sudo already enabled."
else
  # Preserve anything already in the file rather than clobbering it — a plain
  # `tee` here would discard unrelated rules someone had added.
  if [ -s /etc/pam.d/sudo_local ]; then
    printf '%s\n' "$PAM_TID" | sudo tee -a /etc/pam.d/sudo_local >/dev/null
  else
    printf '%s\n' "$PAM_TID" | sudo tee /etc/pam.d/sudo_local >/dev/null
  fi
  success "Touch ID for sudo enabled (/etc/pam.d/sudo_local)."
fi

# Legacy cleanup only: older setups edited /etc/pam.d/sudo directly. With
# sudo_local in place that line is redundant, but only touch the file if it is
# actually there — a no-op sed on a system PAM file every run is a needless risk.
if grep -q '^[^#]*pam_tid\.so' /etc/pam.d/sudo 2>/dev/null; then
  sudo cp /etc/pam.d/sudo "/etc/pam.d/sudo.backup-$(date +%Y%m%d-%H%M%S)"
  sudo sed -i '' '/pam_tid.so/d' /etc/pam.d/sudo \
    && info "Removed the legacy pam_tid line from /etc/pam.d/sudo (backed up)."
fi

#------------------------------------------------------------------------------
title "App preferences"
#------------------------------------------------------------------------------
# iTerm2 reads its prefs from a folder rather than a symlinked plist: point it at
# iterm/ and it picks up com.googlecode.iterm2.plist from there. This was set by
# hand on the current machine and left out of the script, so a fresh box kept the
# repo's plist but never loaded it. Written unconditionally — `defaults write` is
# idempotent, and iTerm2 only reads these at launch.
if [ -d "$DOTFILES_DIR/iterm" ]; then
  defaults write com.googlecode.iterm2 PrefsCustomFolder -string "$DOTFILES_DIR/iterm"
  defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true
  success "iTerm2 prefs folder → $DOTFILES_DIR/iterm"
fi

# obsidian/ holds the "Amethyst Night" theme. It is intentionally NOT deployed
# here: Obsidian themes live at <vault>/.obsidian/themes/, and the vault path is
# per-machine — there is no vault on this one yet (no .obsidian directory exists
# under $HOME). Copy obsidian/themes/* into <vault>/.obsidian/themes/ by hand
# once a vault exists; symlinking into a synced vault tends to confuse Obsidian.

#------------------------------------------------------------------------------
title "Optional setup scripts"
#------------------------------------------------------------------------------
# Opt-in and off by default — see run_setup_scripts in setup/lib.sh for how the
# selection works. macos.sh and mas.sh appear in this `all` list and not in the
# Linux one: one rewrites system defaults, the other drives the Mac App Store.
#
#     SETUP_SCRIPTS="npm composer" ./install.sh
#     SETUP_SCRIPTS=all ./install.sh
run_setup_scripts "macos npm composer mas gh-extensions"

success "\nDone. Open a new terminal (or run: exec zsh) to load the new shell."
