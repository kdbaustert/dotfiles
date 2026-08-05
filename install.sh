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
# .vimrc and .default-npm-packages were dropped from this list: neither has ever
# existed in the repo, so they warned on every single run — two guaranteed
# warnings is exactly how you learn to stop reading them.
for f in .zshenv .zshrc .gitconfig .gitignore .editorconfig .eslintrc .eslintignore \
         .prettierrc .prettierignore .stylelintrc tsconfig.json; do
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
  #
  # Started in the BACKGROUND: this is the longest single step in the script and
  # it is pure network I/O, while the zinit section below is a git clone plus
  # some CPU. Running them concurrently overlaps the two instead of paying for
  # both in series. Output goes to a log so it can't interleave with ours; the
  # wait, the exit status and the DB checks are all handled after zinit, under
  # "Finishing ClamAV setup".
  FRESHCLAM_LOG="$(mktemp -t freshclam)"
  if [ ! -f "$CLAM_PREFIX/var/lib/clamav/daily.cvd" ]; then
    info "Downloading ClamAV signatures in the background (~120MB)..."
  else
    info "Refreshing ClamAV signatures in the background..."
  fi
  freshclam >"$FRESHCLAM_LOG" 2>&1 &
  FRESHCLAM_PID=$!
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

# Launch a zsh once so zinit installs the declared plugins.
#
# Every plugin is turbo-deferred (`wait lucid`), so they are scheduled rather
# than loaded — a plain `zsh -ic exit` would exit before any of them downloads.
# This used to be handled with `sleep 3`, which is wrong in both directions: too
# short on a cold cache or slow link (plugins clone from GitHub), and three
# wasted seconds when they are already installed.
#
# zinit exposes the scheduler directly for exactly this case: `@zinit-scheduler
# burst` marks every queued task as timed-out and runs them one by one, which is
# documented upstream as the way to "run package installations from script, not
# from prompt". It returns when the queue is genuinely drained.
if command -v zsh &>/dev/null; then
  info "Installing zsh plugins (first run clones from GitHub — may take a moment)..."
  if zsh -ic '
        # Drain the turbo queue synchronously instead of racing a fixed sleep.
        # Fall back to a bounded poll if this zinit predates `burst`.
        if (( $+functions[@zinit-scheduler] )); then
          @zinit-scheduler burst &>/dev/null
        else
          for _ in {1..30}; do
            (( ${#ZINIT_TASKS} <= 1 )) && break
            sleep 1
          done
        fi
        zinit self-update &>/dev/null
        zinit compile --all &>/dev/null
        exit 0
      ' 2>/dev/null; then
    success "Plugins installed & compiled."
  else
    warning "Plugin bootstrap incomplete — it finishes on first interactive shell."
  fi
fi

#------------------------------------------------------------------------------
title "Finishing ClamAV setup"
#------------------------------------------------------------------------------
# Collect the background freshclam started above, then do everything that
# genuinely depends on the signatures being on disk.
if [ -n "${FRESHCLAM_PID:-}" ]; then
  info "Waiting for the signature download to finish..."
  if wait "$FRESHCLAM_PID"; then
    success "ClamAV signatures up to date."
  else
    warning "freshclam failed — run it manually later. Output:"
    sed 's/^/    /' "$FRESHCLAM_LOG" >&2
  fi
  rm -f "$FRESHCLAM_LOG"

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
title "Optional setup scripts"
#------------------------------------------------------------------------------
# Uncomment to run. macos.sh changes system defaults; review before enabling.
# sh "$DOTFILES_DIR/setup/macos.sh"
# sh "$DOTFILES_DIR/setup/npm.sh"
# sh "$DOTFILES_DIR/setup/composer.sh"
# sh "$DOTFILES_DIR/setup/mas.sh"
# sh "$DOTFILES_DIR/setup/gh-extensions.sh"

success "\nDone. Open a new terminal (or run: exec zsh) to load the new shell."
