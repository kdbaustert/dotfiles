#!/usr/bin/env bash
#==============================================================================
#  dotfiles installer (macOS)
#  Idempotent: safe to re-run. Existing real files are backed up before they
#  are replaced by symlinks; existing symlinks are simply re-pointed.
#
#  Each section is a function, run by the selection block at the bottom:
#
#      ./install.sh                   a yes/no for every section
#      ./install.sh brew symlinks     only these two, no questions
#      ./install.sh --skip nix,hosts  the questions, without these two
#      ./install.sh -y                everything, no questions
#      ./install.sh --help            list the section names
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
# print_banner — the DOTFILES wordmark, shown once at the start of a run.
#
# Pasted in rather than generated with figlet: figlet is something this script
# installs, so it cannot be relied on the first time the script runs, and it
# does not ship this "ANSI Shadow" font anyway. Drawn in Voltage's `violet`
# (#6638F0, themes/voltage.md) as 24-bit SGR; the palette keeps violet for fills
# and large glyphs, and six-row block letters are the large-glyph case.
#
# Skipped when stdout is not a terminal, so a run piped to a log file does not
# open with six lines of box-drawing characters and escape codes.
print_banner() {
  [ -t 1 ] || return 0

  printf '\n\033[38;2;102;56;240m'
  cat <<'EOF'
██████╗  ██████╗ ████████╗███████╗██╗██╗     ███████╗███████╗
██╔══██╗██╔═══██╗╚══██╔══╝██╔════╝██║██║     ██╔════╝██╔════╝
██║  ██║██║   ██║   ██║   █████╗  ██║██║     █████╗  ███████╗
██║  ██║██║   ██║   ██║   ██╔══╝  ██║██║     ██╔══╝  ╚════██║
██████╔╝╚██████╔╝   ██║   ██║     ██║███████╗███████╗███████║
╚═════╝  ╚═════╝    ╚═╝   ╚═╝     ╚═╝╚══════╝╚══════╝╚══════╝
EOF
  printf '\033[0m\n'
}

#------------------------------------------------------------------------------
request_sudo() {
  title "Requesting sudo"
  info "Prompting for sudo password..."
  if sudo -v; then
    # Keep sudo alive until this script finishes.
    while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
    success "Sudo credentials updated."
  else
    error "Failed to obtain sudo credentials."
  fi
}

#------------------------------------------------------------------------------
section_xcode() {
  title "Xcode command line tools"
  if xcode-select --print-path &>/dev/null; then
    success "Xcode command line tools already installed."
  elif xcode-select --install &>/dev/null; then
    success "Triggered install of Xcode command line tools — finish the GUI prompt, then re-run."
  else
    warning "Could not trigger Xcode command line tools install."
  fi
}

#------------------------------------------------------------------------------
section_brew() {
  title "Homebrew"
  if ! command -v brew &>/dev/null; then
    info "Installing Homebrew..."
    if /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" \
      && [ -x /opt/homebrew/bin/brew ]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    else
      warning "Homebrew install failed — everything below that needs brew will be skipped."
    fi
  else
    info "Homebrew already installed — updating & upgrading."
    brew update && brew upgrade || warning "brew update/upgrade failed (see above) — continuing with what's already installed."
  fi

  if command -v brew &>/dev/null; then
    info "Installing dependencies from Brewfile..."
    brew bundle install --file="$DOTFILES_DIR/homebrew/Brewfile" || warning "Some Brewfile entries failed (see above)."
    brew analytics off
    brew cleanup
  else
    warning "brew is not on PATH — skipped the Brewfile, analytics opt-out, and cleanup."
  fi
}

#------------------------------------------------------------------------------
section_nix() {
  title "Nix"
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
}

#------------------------------------------------------------------------------
section_symlinks() {
  title "Symlinking dotfiles"
  # Every symlink lives in setup/lib.sh so install-linux.sh deploys exactly the
  # same set. `macos` selects which .gitconfig-os half is linked — the one setting
  # git cannot branch on at runtime.
  link_dotfiles macos
}

#------------------------------------------------------------------------------
section_claude() {
  title "Claude Code (plugins, usage cache refresh)"
  # One section for the two Claude Code steps that are not symlinks, so setting
  # up Claude on a machine is a single answer rather than two scattered through
  # the run. The .claude files themselves (CLAUDE.md, hooks, skills, agents) are
  # deployed by the symlinks section, which runs before this one.

  # See CLAUDE_PLUGINS and install_claude_plugins in setup/lib.sh — the plugin
  # list is declared once there, shared with install-linux.sh, and installing
  # has to be a command run again on every machine rather than a symlink like
  # the rest of .claude.
  install_claude_plugins "${CLAUDE_PLUGINS[@]}"

  # The usage cache LaunchAgent keeps ~/.cache/claude-usage.json warm between
  # Claude Code sessions — see the "THE REFRESHER" comment in
  # .claude/statusline.sh for why a session-less gap otherwise leaves the cache
  # up to an hour stale. macOS-only, so it lives here rather than in
  # link_dotfiles() (setup/lib.sh), which install-linux.sh shares and which has
  # no LaunchAgent equivalent to reach for.
  LAUNCH_AGENT_LABEL="dev.kennyb.claude-usage-refresh"
  LAUNCH_AGENT_PLIST="$HOME/Library/LaunchAgents/$LAUNCH_AGENT_LABEL.plist"
  mkdir -p "$HOME/Library/LaunchAgents"
  link "$DOTFILES_DIR/launchd/$LAUNCH_AGENT_LABEL.plist" "$LAUNCH_AGENT_PLIST"

  # bootout-then-bootstrap rather than a load/already-loaded check: it is what
  # makes a re-run pick up an edited plist (StartInterval, etc.), and booting out
  # an agent that was never loaded just fails quietly.
  launchctl bootout "gui/$(id -u)/$LAUNCH_AGENT_LABEL" &>/dev/null
  launchctl bootstrap "gui/$(id -u)" "$LAUNCH_AGENT_PLIST" &>/dev/null

  # The verdict comes from `print`, not from what bootstrap returned. bootout can
  # return before launchd has finished tearing the job down, and the bootstrap
  # behind it then fails *because the job is still there* — an error that means
  # the agent is loaded, which is the opposite of what reporting that exit status
  # would say. Asking what state launchd ended up in answers the only question
  # this step actually cares about.
  if launchctl print "gui/$(id -u)/$LAUNCH_AGENT_LABEL" &>/dev/null; then
    success "Loaded $LAUNCH_AGENT_LABEL — refreshes the usage cache every 5 minutes."
  else
    warning "Could not load $LAUNCH_AGENT_LABEL — the usage cache will only refresh during an active Claude Code session."
  fi
}

#------------------------------------------------------------------------------
section_zsh() {
  title "zsh (pay-respects, LS_COLORS, zinit, Voltage themes)"
  # Everything the shell needs beyond its symlinked config, as one answer rather
  # than four. Runs after the symlinks section because the zinit and theme steps
  # launch `zsh -ic`, which has to find the linked ~/.zshrc. The order inside is
  # load-bearing only at the end: the fast-syntax-highlighting half of the theme
  # step calls `fast-theme`, a plugin function that exists once zinit has
  # installed the plugin, so zinit comes before the themes.

  # pay-respects — command correction (the `fuck` alias and ^X^X in .zshrc). Not
  # installed via Homebrew: there is no formula in core, and the tap the upstream
  # README points at (timescam/homebrew-tap) is a 2-star third-party repo owned
  # by someone other than the project author that pins `version "nightly"` — a
  # moving target for a tool that reads the command line. So: pull the author's
  # own signed release, pinned and checksummed, into ~/.local/bin (already on
  # PATH via .zprofile).
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

  # The second LS_COLORS database (trapd00r), alongside the vivid/Voltage one
  # that .zshrc defaults to. Why it is a clone rather than a release, and why it
  # is not a zinit plugin, is in setup/lib.sh — identical on both platforms, so
  # the reasoning lives with the code rather than being copied into two
  # installers.
  install_ls_colors

  bootstrap_zinit

  build_themes
}

#------------------------------------------------------------------------------
section_hosts() {
  title "Hosts blocklist (LaunchDaemon)"
  # Splices the blocklist into /etc/hosts now and installs the root job that
  # re-splices it every Monday — see the header of setup/hosts.sh for why a root
  # job is acceptable here. Unlike the agent above, both files are root owned and
  # never linked: the daemon must not run anything I can edit, and launchd
  # refuses a daemon plist not owned by root. That makes this section what
  # carries an edit to setup/hosts.sh or the plist over to the running job.
  #
  # install(1) rather than cp, because it sets owner and mode in the same step,
  # leaving no moment where the copy root will run is writable by me. Every step
  # rides the sudo session request_sudo opened.
  #
  # The label is built from the account running the installer, not written into
  # the repo, so the same checkout installs cleanly under any user name. For the
  # same reason the plist is generated here rather than tracked in launchd/: the
  # label and both paths inside it all carry that name. `id -un` rather than
  # $USER, which is unset in some non-login contexts.
  HOSTS_DAEMON_LABEL="local.$(id -un).hosts-refresh"
  HOSTS_DAEMON_PLIST="/Library/LaunchDaemons/$HOSTS_DAEMON_LABEL.plist"
  HOSTS_DAEMON_SCRIPT="/usr/local/libexec/$HOSTS_DAEMON_LABEL"
  HOSTS_DAEMON_LOG="/var/log/$HOSTS_DAEMON_LABEL.log"
  hosts_plist_tmp="$(mktemp)"

  # StartCalendarInterval rather than StartInterval: a calendar job that came
  # due while the Mac slept runs once on wake instead of being skipped. One
  # missed while the Mac was shut down is not made up; the next Monday catches it.
  # --scheduled only adds a dated line to the log — launchd's has no timestamps.
  cat >"$hosts_plist_tmp" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>$HOSTS_DAEMON_LABEL</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string>
    <string>$HOSTS_DAEMON_SCRIPT</string>
    <string>--scheduled</string>
  </array>
  <key>StartCalendarInterval</key>
  <dict>
    <key>Weekday</key>
    <integer>1</integer>
    <key>Hour</key>
    <integer>10</integer>
    <key>Minute</key>
    <integer>0</integer>
  </dict>
  <key>StandardOutPath</key>
  <string>$HOSTS_DAEMON_LOG</string>
  <key>StandardErrorPath</key>
  <string>$HOSTS_DAEMON_LOG</string>
</dict>
</plist>
EOF

  # Linted before it goes anywhere near /Library: with no tracked copy, the
  # `plutil -lint launchd/*.plist` check in CLAUDE.md never sees this file.
  if plutil -lint -s "$hosts_plist_tmp" \
    && sudo install -d -o root -g wheel -m 755 "$(dirname "$HOSTS_DAEMON_SCRIPT")" \
    && sudo install -o root -g wheel -m 755 "$DOTFILES_DIR/setup/hosts.sh" "$HOSTS_DAEMON_SCRIPT" \
    && sudo install -o root -g wheel -m 644 "$hosts_plist_tmp" "$HOSTS_DAEMON_PLIST"; then
    # Same bootout-then-bootstrap and same verdict-from-print as the agent above,
    # for the same race.
    sudo launchctl bootout "system/$HOSTS_DAEMON_LABEL" &>/dev/null
    sudo launchctl bootstrap system "$HOSTS_DAEMON_PLIST" &>/dev/null

    if launchctl print "system/$HOSTS_DAEMON_LABEL" &>/dev/null; then
      success "Loaded $HOSTS_DAEMON_LABEL — refreshes /etc/hosts every Monday at 10:00."
    else
      warning "Could not load $HOSTS_DAEMON_LABEL — the blocklist will only update when setup/hosts.sh is run by hand."
    fi
  else
    warning "Could not copy the hosts refresh job into place — the blocklist will only update when setup/hosts.sh is run by hand."
  fi
  rm -f "$hosts_plist_tmp"

  if "$DOTFILES_DIR/setup/hosts.sh"; then
    success "Hosts blocklist current."
  else
    warning "setup/hosts.sh exited non-zero — /etc/hosts left as it was; see the output above."
  fi
}

#------------------------------------------------------------------------------
section_touchid() {
  title "Touch ID for sudo"
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
    if grep -q '^[^#]*pam_tid\.so' /etc/pam.d/sudo_local 2>/dev/null; then
      success "Touch ID for sudo enabled (/etc/pam.d/sudo_local)."
    else
      warning "Could not write /etc/pam.d/sudo_local — Touch ID for sudo stays disabled."
    fi
  fi

  # Legacy cleanup only: older setups edited /etc/pam.d/sudo directly. With
  # sudo_local in place that line is redundant, but only touch the file if it is
  # actually there — a no-op sed on a system PAM file every run is a needless risk.
  if grep -q '^[^#]*pam_tid\.so' /etc/pam.d/sudo 2>/dev/null; then
    if sudo cp /etc/pam.d/sudo "/etc/pam.d/sudo.backup-$(date +%Y%m%d-%H%M%S)"; then
      sudo sed -i '' '/pam_tid.so/d' /etc/pam.d/sudo \
        && info "Removed the legacy pam_tid line from /etc/pam.d/sudo (backed up)." \
        || warning "Could not remove the legacy pam_tid line from /etc/pam.d/sudo — harmless (sudo_local already covers it) but worth a look."
    else
      warning "Could not back up /etc/pam.d/sudo — skipped the legacy pam_tid cleanup rather than sed without a backup."
    fi
  fi
}

#------------------------------------------------------------------------------
section_iterm() {
  title "iTerm preferences"
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
}

#------------------------------------------------------------------------------
section_setup_scripts() {
  title "Optional setup scripts"
  # Opt-in and off by default — see run_setup_scripts in setup/lib.sh for how the
  # selection works. mas.sh appears in this `all` list and not in the Linux one,
  # because it drives the Mac App Store. macos.sh used to be here too and is now
  # the `macos` section below, so it gets a yes/no of its own instead of hiding
  # behind an environment variable.
  #
  #     SETUP_SCRIPTS="pnpm composer" ./install.sh
  #     SETUP_SCRIPTS=all ./install.sh
  run_setup_scripts "pnpm composer mas gh-extensions"
}

#------------------------------------------------------------------------------
section_macos() {
  title "macOS system defaults"
  # setup/macos.sh rewrites system settings (Finder, Dock, the save panel, the
  # computer name) — review it before saying yes. It stays a script of its own,
  # as setup/hosts.sh does, rather than being pasted in here: it is 180 lines of
  # `defaults write`, and it can still be run by hand.
  #
  # Last on purpose. The script ends by killing Dock, Finder, SystemUIServer and
  # Terminal so they reread their settings — and when the installer is running
  # in Terminal.app, that kills the installer too. As the final section, the only
  # thing that loss can cost is the summary.
  if "$DOTFILES_DIR/setup/macos.sh"; then
    success "macOS defaults applied — some take effect only after a logout."
  else
    warning "setup/macos.sh exited non-zero — see the output above."
  fi
}

#==============================================================================
#  Section selection
#==============================================================================
# Every section, in the order a full run takes them, as "name|description".
# The order is load-bearing — the theme step calls the bat the Brewfile
# installs, zinit reads the .zshrc the symlink step puts in place — so a
# partial run keeps it too: `./install.sh theme brew` still runs brew first.
# "name|description" strings rather than an associative array because a fresh
# Mac runs this under /bin/bash 3.2, before Homebrew's bash exists.
SECTIONS=(
  "xcode|Xcode command line tools"
  "brew|Homebrew, then everything in homebrew/Brewfile"
  "nix|Nix, multi-user daemon"
  "symlinks|Symlink every dotfile into \$HOME"
  "claude|Claude Code plugins and the usage cache LaunchAgent"
  "zsh|pay-respects, LS_COLORS, zinit plugins, Voltage themes (bat, syntax highlighting)"
  "hosts|Hosts blocklist and its weekly LaunchDaemon"
  "touchid|Touch ID for sudo"
  "iterm|(iTerm2) Preferences"
  "setup-scripts|Optional setup/ scripts, selected by \$SETUP_SCRIPTS"
  "macos|macOS system defaults from setup/macos.sh — review it first"
)

# The sections that call sudo. The prompt used to open every run, which was
# right when every run was a full one; `./install.sh symlinks` should not ask
# for a password it never uses. brew is here for the Homebrew installer and
# for casks that ship a .pkg; macos because setup/macos.sh runs sudo itself.
# setup-scripts used to be here for that same reason and left with macos.sh —
# none of the scripts still behind it calls sudo.
SUDO_SECTIONS="brew nix hosts touchid macos"

# usage — print the section list, generated from SECTIONS so it cannot drift.
usage() {
  local entry

  echo "Usage: ./install.sh [-y] [section...] [--skip section[,section...]]"
  echo
  echo "With no section names, each section asks a yes/no first, all before anything"
  echo "runs. Name one or more to run only those, without questions. Either way they"
  echo "run in the order below."
  echo
  echo "  --skip LIST   leave these out (comma-separated, repeatable)"
  echo "  -y, --yes     no questions — run everything that is not skipped"
  echo "  -h, --help    show this list"
  echo
  for entry in "${SECTIONS[@]}"; do
    printf '  %-16s %s\n' "${entry%%|*}" "${entry#*|}"
  done
}

# has_word <list> <word> — whether a space-separated list contains the word.
# A padded substring match rather than an array, which bash 3.2 cannot pass
# into a function and which `set -u` trips on when it is empty.
has_word() {
  [[ " $1 " == *" $2 "* ]]
}

# describe <name> — the description half of a SECTIONS entry.
describe() {
  local entry

  for entry in "${SECTIONS[@]}"; do
    if [ "${entry%%|*}" = "$1" ]; then
      echo "${entry#*|}"
      return 0
    fi
  done
}

# The yes/no questions are drawn with gum — Charm's prebuilt CLI over their
# Bubble Tea TUI framework. A prebuilt binary rather than a Bubble Tea
# program of our own because the questions have to work on a fresh Mac, which
# has no Go toolchain to build one with (go is not in the Brewfile), and gum
# is the same framework with none of the Go code to maintain.
#
# Fetched pinned and checksummed into ~/.local/bin, the pay-respects pattern,
# rather than from the Brewfile: the questions decide whether the brew
# section runs at all, so it cannot depend on it. To bump: change GUM_VERSION,
# then update GUM_SHA256 from the release's checksums.txt.
GUM_VERSION="2.0.2"
GUM_SHA256="4777a69b1170b8db23c95d5889fb32186cfda1a3ac950d339aa17e3513633890"
GUM=""

# ensure_gum — point GUM at a gum binary, fetching the pinned release when
# there is none. Leaves GUM empty when it can't (offline, not arm64), and the
# plain read-based prompts below take over, so gum never blocks a run.
ensure_gum() {
  local asset="gum_${GUM_VERSION}_Darwin_arm64"
  local url="https://github.com/charmbracelet/gum/releases/download/v${GUM_VERSION}/${asset}.tar.gz"
  local tmp

  GUM="$(command -v gum || true)"
  if [ -z "$GUM" ] && [ -x "$HOME/.local/bin/gum" ]; then
    GUM="$HOME/.local/bin/gum"
  fi

  if [ -n "$GUM" ] || [ "$(uname -m)" != "arm64" ]; then
    return 0
  fi

  info "Fetching gum ${GUM_VERSION} for the installer's questions..."
  tmp="$(mktemp -d)"
  if curl -sSfL -o "$tmp/$asset.tar.gz" "$url" \
    && echo "${GUM_SHA256}  $tmp/$asset.tar.gz" | shasum -a 256 -c - >/dev/null 2>&1 \
    && tar -xzf "$tmp/$asset.tar.gz" -C "$tmp"; then
    mkdir -p "$HOME/.local/bin"
    install -m 755 "$tmp/$asset/gum" "$HOME/.local/bin/gum"
    GUM="$HOME/.local/bin/gum"
  else
    warning "Could not fetch gum (download or checksum) — using plain prompts instead."
  fi
  rm -rf "$tmp"
}

# confirm <question> — yes/no, defaulting to yes. Ctrl-C aborts the whole run
# instead of reading as "no": gum reports it as 130, and a bare `read` sees EOF.
confirm() {
  local reply status

  if [ -n "$GUM" ]; then
    "$GUM" confirm "$1"
    status=$?
    [ "$status" -eq 130 ] && exit 130
    return "$status"
  fi

  read -r -p "$1 [Y/n] " reply || exit 130
  [[ ! $reply =~ ^[Nn] ]]
}

# Parse everything before running anything, so a typo in the last argument
# does not surface after the first two sections have already run.
ALL_SECTIONS=""
for entry in "${SECTIONS[@]}"; do
  ALL_SECTIONS+="${entry%%|*} "
done

REQUESTED=""
SKIPPED=""
ASSUME_YES=false

while [ $# -gt 0 ]; do
  case "$1" in
    -h | --help | help)
      usage
      exit 0
      ;;
    -y | --yes)
      ASSUME_YES=true
      ;;
    --skip)
      [ $# -ge 2 ] || error "--skip needs a section name — see ./install.sh --help"
      SKIPPED+="${2//,/ } "
      shift
      ;;
    --skip=*)
      SKIPPED+="${1#--skip=} "
      SKIPPED="${SKIPPED//,/ }"
      ;;
    -*)
      usage
      error "Unknown option: $1"
      ;;
    *)
      REQUESTED+="$1 "
      ;;
  esac
  shift
done

for name in $REQUESTED $SKIPPED; do
  if ! has_word "$ALL_SECTIONS" "$name"; then
    usage
    error "Unknown section: $name"
  fi
done

# After the arguments are validated, so --help and a mistyped section name get
# their message without the banner in front of it.
print_banner

# Interactive only when nothing was named — named sections were already
# chosen, so asking about them again would be noise — and only when there is
# someone to ask: with stdin not a terminal (piped, cron, ssh without -t) a
# question would hang or read EOF, so that run behaves as -y does.
INTERACTIVE=false
if ! $ASSUME_YES && [ -z "$REQUESTED" ] && [ -t 0 ]; then
  INTERACTIVE=true
  ensure_gum
fi

SELECTED=""
for name in ${REQUESTED:-$ALL_SECTIONS}; do
  has_word "$SKIPPED" "$name" || SELECTED+="$name "
done

# A yes/no per section is how an interactive run is chosen. Every question
# comes up front rather than as each section is reached: a full run is long,
# and a question halfway through would sit there until someone came back.
if $INTERACTIVE; then
  CONFIRMED=""
  for name in $SELECTED; do
    question="Run $name? $(describe "$name")"
    has_word "$SUDO_SECTIONS" "$name" && question+=" (uses sudo)"

    if confirm "$question"; then
      CONFIRMED+="$name "
    fi
  done
  SELECTED="$CONFIRMED"

  if [ -z "$SELECTED" ]; then
    info "Nothing chosen — exiting without running anything."
    exit 0
  fi
fi

for name in $SUDO_SECTIONS; do
  if has_word "$SELECTED" "$name"; then
    request_sudo
    break
  fi
done

for name in $ALL_SECTIONS; do
  if has_word "$SELECTED" "$name"; then
    "section_${name//-/_}"
  fi
done

#------------------------------------------------------------------------------
title "Summary"
#------------------------------------------------------------------------------
print_summary

success "\nDone. Open a new terminal (or run: exec zsh) to load the new shell."
