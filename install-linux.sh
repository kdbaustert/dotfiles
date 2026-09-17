#!/usr/bin/env bash
#==============================================================================
#  dotfiles installer (Arch / Manjaro)
#  Idempotent: safe to re-run. Existing real files are backed up before they
#  are replaced by symlinks; existing symlinks are simply re-pointed.
#------------------------------------------------------------------------------
#  The sibling of install.sh, not a fork of it. Everything the two machines do
#  identically — the symlinks, zinit, the theme caches, LS_COLORS, pay-respects,
#  the setup-script runner — lives in setup/lib.sh and is called from both. What
#  is left here is only what pacman, systemd and fontconfig do differently from
#  Homebrew, PAM and CoreText.
#
#  Read setup/lib.sh's header before adding anything: a section that would be
#  the same on macOS belongs there, or it will drift.
#==============================================================================

set -uo pipefail

DOTFILES_DIR="${DOTFILES:-$HOME/dotfiles}"

# shellcheck source=setup/lib.sh
source "$DOTFILES_DIR/setup/lib.sh"

#------------------------------------------------------------------------------
title "Sanity check"
#------------------------------------------------------------------------------
# Guard rather than assume: this script writes to ~/.config, installs packages
# with pacman and links a Linux-only .gitconfig-os. Running it on a Mac would
# fail late and messily, and running install.sh here would try to install
# Homebrew.
if [ "$(uname -s)" != "Linux" ]; then
  error "This is the Linux installer and this is $(uname -s) — run ./install.sh instead."
fi
if ! command -v pacman &>/dev/null; then
  error "No pacman found. This installer targets Arch and Manjaro; adapt the package step for another distro."
fi

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
title "Packages (pacman)"
#------------------------------------------------------------------------------
# arch/pkglist is the counterpart to homebrew/Brewfile. Its names were
# transcribed rather than verified — see that file's header — so every one is
# checked against the sync database BEFORE anything is installed, and the
# unknown ones are reported rather than aborting the transaction. `pacman -S`
# on a list containing one bad name installs nothing at all, which on a fresh
# machine would mean a single typo costs the whole run.
read_pkglist() {
  # Strip comments and blank lines. Deliberately not `grep -v '^#'` alone:
  # trailing comments after a name would survive that.
  sed -e 's/#.*//' -e 's/[[:space:]]*$//' -e '/^$/d' "$1"
}

PKGLIST="$DOTFILES_DIR/arch/pkglist"
if [ ! -f "$PKGLIST" ]; then
  warning "No $PKGLIST — skipping the pacman step."
else
  # </dev/null on every pacman/AUR-helper call below: --noconfirm answers the
  # ordinary proceed/replace prompts, but pacman's "Do you want to skip the
  # above package for this upgrade?" prompt (shown when a locally installed
  # version is newer than the repo's, e.g. after building something from AUR)
  # is a separate --ask bit that --noconfirm does not reliably cover. With
  # stdin still attached to the terminal, pacman just sits waiting on a
  # keypress the script never sends — closing stdin makes it take the
  # non-interactive default instead of hanging.
  info "Refreshing the package databases..."
  sudo pacman -Sy --noconfirm </dev/null &>/dev/null || warning "pacman -Sy failed; continuing with the cached database."

  known=()
  unknown=()
  while IFS= read -r pkg; do
    [ -n "$pkg" ] || continue
    if pacman -Si -- "$pkg" &>/dev/null || pacman -Sg -- "$pkg" &>/dev/null; then
      known+=("$pkg")
    else
      unknown+=("$pkg")
    fi
  done < <(read_pkglist "$PKGLIST")

  if [ ${#unknown[@]} -gt 0 ]; then
    warning "Not in the repos, skipped — fix the name in arch/pkglist or move it to arch/aurlist:"
    printf '         %s\n' "${unknown[@]}"
  fi

  if [ ${#known[@]} -gt 0 ]; then
    info "Installing ${#known[@]} packages (--needed, so already-installed ones are skipped)..."
    # --needed is what makes this idempotent: it turns a reinstall into a no-op
    # rather than redownloading the whole list on every run.
    sudo pacman -S --needed --noconfirm -- "${known[@]}" </dev/null \
      && success "Repo packages installed." \
      || warning "Some packages failed (see above)."
  fi
fi

#------------------------------------------------------------------------------
title "Packages (AUR)"
#------------------------------------------------------------------------------
# No AUR helper is installed by this script. Bootstrapping one means cloning and
# makepkg-ing it, which is a decision about which helper you want rather than a
# step that has one right answer — and a machine that has none still gets
# everything in pkglist, so this degrades to a warning rather than an error.
AUR_HELPER=""
for h in paru yay; do
  command -v "$h" &>/dev/null && AUR_HELPER="$h" && break
done

# --noconfirm only answers pacman/makepkg prompts. Both helpers also have their
# own PKGBUILD diff/edit menus that --noconfirm does not silence, so without
# these the helper can sit waiting on a keypress the &>/dev/null below hides —
# looking exactly like a hang rather than a paused prompt. The flag names differ
# per helper: yay uses --answer*, paru uses --skipreview/--noupgrademenu.
case "$AUR_HELPER" in
paru) AUR_HELPER_FLAGS=(--skipreview --noupgrademenu) ;;
yay) AUR_HELPER_FLAGS=(--answerdiff None --answeredit None --answerclean None --answerupgrade None) ;;
*) AUR_HELPER_FLAGS=() ;;
esac

AURLIST="$DOTFILES_DIR/arch/aurlist"
if [ -z "$AUR_HELPER" ]; then
  warning "No AUR helper (paru/yay) found — skipping arch/aurlist. Install one, then re-run."
elif [ ! -f "$AURLIST" ]; then
  info "No $AURLIST — nothing to do."
else
  mapfile -t aur < <(read_pkglist "$AURLIST")
  if [ ${#aur[@]} -gt 0 ]; then
    info "Installing ${#aur[@]} AUR packages with $AUR_HELPER..."
    # One at a time, unlike the pacman batch: an AUR package builds from source
    # and any one of them can fail on its own, and a batch would take the rest
    # down with it. Slower, but a missing iris should not cost firebase-tools.
    #
    # Build output is silenced, and an AUR build can run for minutes with
    # nothing else on screen — spinner_run keeps a live spinner + elapsed time
    # on screen for each package, so a slow build reads as "still going"
    # rather than "stuck".
    aur_n=0
    for pkg in "${aur[@]}"; do
      aur_n=$((aur_n + 1))
      if spinner_run "[$aur_n/${#aur[@]}] Building $pkg..." \
        "$AUR_HELPER" -S --needed --noconfirm "${AUR_HELPER_FLAGS[@]}" -- "$pkg"; then
        success "AUR: $pkg"
      else
        warning "AUR: $pkg failed — see arch/aurlist for which of these are expected to be missing."
      fi
    done
  fi
fi

#------------------------------------------------------------------------------
title "command-not-found database"
#------------------------------------------------------------------------------
# pkgfile ships the handler zsh/os/linux-interactive.zsh sources, but installs
# an EMPTY files database — until this runs, an unknown command suggests
# nothing and looks broken rather than unconfigured. The timer keeps it current
# afterwards, which is why this is a one-time step rather than something the
# shell does.
if command -v pkgfile &>/dev/null; then
  info "Building the pkgfile database (first run downloads a few MB)..."
  sudo pkgfile -u &>/dev/null \
    && success "pkgfile database built." \
    || warning "pkgfile -u failed — command-not-found will suggest nothing until it succeeds."
  sudo systemctl enable --now pkgfile-update.timer &>/dev/null \
    && success "pkgfile-update.timer enabled." \
    || info "Could not enable pkgfile-update.timer; refresh by hand with: sudo pkgfile -u"
else
  info "pkgfile not installed — command-not-found stays silent (harmless)."
fi

#------------------------------------------------------------------------------
title "Nix"
#------------------------------------------------------------------------------
# Same role as on macOS: Homebrew's place is taken by pacman, and Nix still owns
# per-project environments through `nix-shell` and `nix develop`. Don't install
# through Nix what arch/pkglist already has — a second copy only drifts.
#
# Upstream's installer with --no-modify-profile, matching install.sh, and for
# the same reason: .zprofile sources the daemon hook itself from a tracked file.
# The path is identical on Linux (/nix/var/nix/profiles/default/...), which is
# why that line in .zprofile needed no platform branch.
#
# Two differences from the macOS call, both harmless to state: there is no APFS
# volume to create — /nix is a plain directory on the root filesystem — and
# --daemon is a genuine choice here rather than the only accepted mode, taken so
# the two machines have the same multi-user layout and the same profile paths.
#
# NB: Arch also packages Nix (`nix` in extra), and that would work. Upstream's
# installer is used anyway so both machines run the same Nix, installed the same
# way, with the same channel — a distro package would put pacman in charge of
# the interpreter on one machine and not the other.
NIX_BIN="/nix/var/nix/profiles/default/bin/nix"
if [ -x "$NIX_BIN" ]; then
  info "Nix already installed ($("$NIX_BIN" --version))."
else
  info "Installing Nix (multi-user daemon)..."
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
# Same pinned-release install as macOS (see install_pay_respects in
# setup/lib.sh); only the asset and its checksum differ.
#
# One checksum per architecture, because the asset differs per architecture
# and a single PR_SHA256 could only ever have been right for one of them.
# Both were computed on 2026-09-16 by fetching the v0.8.8 assets from the
# release and running `shasum -a 256` — the same thing the library does before
# it installs, so a mismatch here fails safely with "download, checksum, or
# extract" rather than installing something unverified. Re-derive both when
# bumping PR_VERSION:
#
#   for a in x86_64 aarch64; do
#     f=pay-respects-<ver>-$a-unknown-linux-musl.tar.zst
#     curl -sSfL -O https://github.com/iffse/pay-respects/releases/download/v<ver>/$f
#     sha256sum $f
#   done
#
# musl rather than gnu: the static build has no glibc version floor, which
# matters on a rolling distro only in that it removes a variable.
PR_VERSION="0.8.8"

case "$(uname -m)" in
  x86_64)
    PR_ARCH="x86_64-unknown-linux-musl"
    PR_SHA256="20bb89e9fa114b20ce78b57ece77134e79e314fd0d5086e9695c0de7f98ccaaf"
    ;;
  aarch64)
    PR_ARCH="aarch64-unknown-linux-musl"
    PR_SHA256="c63ce37f25f4b8f7fc8ffd46955a22cb05314991560822f7de77e8190d3d9ca4"
    ;;
  *)
    PR_ARCH=""
    PR_SHA256=""
    ;;
esac

if [ -z "$PR_ARCH" ]; then
  warning "Skipping pay-respects — no release asset pinned for $(uname -m)."
else
  install_pay_respects "$PR_VERSION" "$PR_SHA256" \
    "pay-respects-${PR_VERSION}-${PR_ARCH}.tar.zst"
fi

#------------------------------------------------------------------------------
title "LS_COLORS (trapd00r)"
#------------------------------------------------------------------------------
# The second LS_COLORS database, alongside the vivid/Voltage one that .zshrc
# defaults to. Identical to the macOS step — and the one place where Linux is
# the simpler platform: .zshrc's probe finds a plain `dircolors` here rather
# than needing Homebrew's g-prefixed one.
install_ls_colors

#------------------------------------------------------------------------------
title "Symlinking dotfiles"
#------------------------------------------------------------------------------
# Every symlink lives in setup/lib.sh so this deploys exactly what install.sh
# does. `linux` selects which .gitconfig-os half is linked — the one setting git
# cannot branch on at runtime.
link_dotfiles linux

#------------------------------------------------------------------------------
title "Claude Code plugins"
#------------------------------------------------------------------------------
# Identical to install.sh's step — see install_claude_plugins in setup/lib.sh.
# swift-lsp only matters on the macOS side (no SourceKit-LSP on Arch), but
# installing the same four here keeps the plugin set itself the same on every
# machine, the same reason link_dotfiles deploys every skill unconditionally
# rather than picking per OS.
install_claude_plugins php-lsp swift-lsp typescript-lsp miro

#------------------------------------------------------------------------------
title "Bootstrapping zinit + plugins"
#------------------------------------------------------------------------------
bootstrap_zinit

#------------------------------------------------------------------------------
title "Theme (Voltage)"
#------------------------------------------------------------------------------
build_themes

#------------------------------------------------------------------------------
title "Fonts"
#------------------------------------------------------------------------------
# The Nerd Font families the terminal configs name come from arch/pkglist, so
# there is nothing to copy — this only refreshes fontconfig's cache so a
# just-installed family is visible without a logout.
#
# Note what is deliberately NOT here: fonts/HackNerdFontColor-Regular.ttf, the
# COLR/CPAL build that colours Ghostty's tab icons. That whole mechanism
# (zsh/extra/tabtitle.zsh and the font it needs) works around the macOS native
# tab bar being an AppKit NSTabBar that cannot hold an image, which is not a
# problem Ghostty's GTK build has. Installing the font here would put a second
# family claiming "Hack Nerd Font Color" on the system to no purpose.
#
# Unlike macOS, a symlinked font WOULD work here — fontconfig follows them,
# where CoreText does not — so if the tab-icon font is ever wanted on Linux it
# belongs in link_dotfiles, not in a copy step.
if command -v fc-cache &>/dev/null; then
  fc-cache -f &>/dev/null \
    && success "Font cache refreshed." \
    || warning "fc-cache failed — a newly installed font may not appear until you log out."
else
  info "fontconfig not present — skipping the font cache refresh."
fi

#------------------------------------------------------------------------------
title "Shell"
#------------------------------------------------------------------------------
# macOS already runs zsh as the login shell, so install.sh never had to do this.
# Arch defaults to bash, and every one of these dotfiles is zsh — without this
# step the install completes and appears to have done nothing.
#
# `chsh` is asked for rather than done silently: it changes how every future
# login behaves, which is exactly the kind of thing this repo's rules say to
# confirm. An already-correct shell says so and asks nothing.
ZSH_BIN="$(command -v zsh)"
if [ -z "$ZSH_BIN" ]; then
  warning "zsh is not installed — the dotfiles will not load. Check the pacman step above."
elif [ "${SHELL:-}" = "$ZSH_BIN" ]; then
  info "Login shell is already $ZSH_BIN."
else
  info "Login shell is ${SHELL:-unset}, not $ZSH_BIN."
  # Read from the terminal, not stdin: this script may be piped.
  if [ -r /dev/tty ] && read -r -p "Change it with chsh? [y/N] " reply </dev/tty \
    && [[ "$reply" =~ ^[Yy]$ ]]; then
    # /etc/shells must list it or chsh refuses; the zsh package adds the entry,
    # so this only fails on a hand-built zsh.
    chsh -s "$ZSH_BIN" \
      && success "Login shell set to $ZSH_BIN — takes effect on next login." \
      || warning "chsh failed. Check that $ZSH_BIN is listed in /etc/shells."
  else
    info "Left unchanged. Run this when you want it: chsh -s $ZSH_BIN"
  fi
fi

#------------------------------------------------------------------------------
title "Manual steps"
#------------------------------------------------------------------------------
# Things this script deliberately does not do, printed rather than left to be
# discovered. Each is either a decision or something that cannot be verified
# from here.
info "Generate the locale .zshenv asks for, if it is not already:"
echo "         sudo sed -i 's/^#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen && sudo locale-gen"
info "Verify the 1Password signing helper path in .gitconfig-linux:"
echo "         ls -l /opt/1Password/op-ssh-sign"
info "Wire the Claude Code hook and status line into ~/.claude/settings.json"
info "     (untracked on purpose — see .claude/hooks/notify.sh's header)."

#------------------------------------------------------------------------------
title "Summary"
#------------------------------------------------------------------------------
print_summary

success "\nDone. Open a new terminal (or run: exec zsh) to load the new shell."
