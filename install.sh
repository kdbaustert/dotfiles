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
title "LS_COLORS (trapd00r)"
#------------------------------------------------------------------------------
# A second LS_COLORS database, kept ALONGSIDE the vivid/Voltage one rather than
# replacing it: .zshrc chooses between them at runtime via $LS_COLORS_SOURCE,
# which defaults to vivid. See that block for why Voltage stays the default.
#
# Cloned, not fetched as a release: upstream publishes no tarball. Only the
# LS_COLORS data file is used — its lscolors.sh wrapper is ignored, because it
# hardcodes `dircolors`, which does not exist on macOS (coreutils installs
# GNU tools g-prefixed and gnubin is off PATH by design).
#
# Deliberately NOT a zinit plugin. Everything zinit loads here is turbo-deferred
# to after the first prompt, but LS_COLORS has to exist before the
# `zstyle ':completion:*' list-colors` line in .zshrc reads it. An eager zinit
# entry would put the plugin machinery back on the critical path — precisely
# what the starship note in zsh/zinit.zsh took it off.
LS_COLORS_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/LS_COLORS"
LS_COLORS_CACHE="${ZSH_CACHE_DIR:-$HOME/.cache/zsh}/init/trapd00r-ls-colors.zsh"

if [ -d "$LS_COLORS_DIR/.git" ]; then
  info "LS_COLORS already cloned — updating."
  if git -C "$LS_COLORS_DIR" pull --quiet --ff-only 2>/dev/null; then
    success "LS_COLORS updated."
  else
    warning "LS_COLORS update failed — keeping the existing clone."
  fi
else
  info "Cloning trapd00r/LS_COLORS..."
  if git clone --quiet --depth=1 https://github.com/trapd00r/LS_COLORS "$LS_COLORS_DIR"; then
    success "LS_COLORS cloned to $LS_COLORS_DIR."
  else
    warning "LS_COLORS clone failed — .zshrc falls back to vivid/Voltage."
  fi
fi

# zcache keys off the *binary's* mtime (gdircolors), so a changed database is
# invisible to it and a pull above would otherwise keep serving the old colours
# forever. Dropping the cache file here is what makes `install.sh` a complete
# update path; `zcache_clear` remains the manual equivalent.
if [ -f "$LS_COLORS_CACHE" ]; then
  rm -f "$LS_COLORS_CACHE" "$LS_COLORS_CACHE.zwc" \
    && info "Dropped the trapd00r LS_COLORS cache — it rebuilds on next shell start."
fi

#------------------------------------------------------------------------------
title "Symlinking dotfiles"
#------------------------------------------------------------------------------
# Root-level dotfiles (only those that exist in the repo are linked).
# .vimrc and .default-npm-packages were dropped from this list: neither has ever
# existed in the repo, so they warned on every single run — two guaranteed
# warnings is exactly how you learn to stop reading them.
for f in .zshenv .zshrc .gitconfig .editorconfig .prettierrc; do
  link "$DOTFILES_DIR/$f" "$HOME/$f"
done

# ~/.hushlogin suppresses the "Last login:" banner. Only its existence matters —
# the contents are never read — so it is created here rather than symlinked.
if [ -e "$HOME/.hushlogin" ]; then
  info "Login banner already suppressed (~/.hushlogin present)."
else
  touch "$HOME/.hushlogin" && success "created ~/.hushlogin"
fi

# Retired links, removed on re-run. Only ever unlinks a SYMLINK whose target is
# inside $DOTFILES_DIR — a real file of the same name is left alone.
for f in .gitignore .eslintrc .eslintignore .stylelintrc .prettierignore \
         tsconfig.json; do
  if [ -L "$HOME/$f" ] && case "$(readlink "$HOME/$f")" in "$DOTFILES_DIR"/*) true ;; *) false ;; esac; then
    rm -f "$HOME/$f" && info "Removed retired symlink ~/$f"
  fi
done

# .zprofile is the zsh login file; also expose it as ~/.profile for parity.
link "$DOTFILES_DIR/.zprofile" "$HOME/.zprofile"
link "$DOTFILES_DIR/.zprofile" "$HOME/.profile"

# Claude Code's global instructions. Only CLAUDE.md is deployed: the rest of
# ~/.claude is state Claude writes itself (settings.local.json, projects/,
# todos/), so the directory is created and linked into, never linked over.
#
# There used to be a second file here, AGENTS.md, linked for the sake of tools
# that DO look for it at user scope and pulled into CLAUDE.md by an `@AGENTS.md`
# import. Claude Code never discovered it on its own — verified against 2.1.231:
# neither ~/.claude/AGENTS.md nor <project>/AGENTS.md is read, only CLAUDE.md is
# — so the import was the only thing loading it, and deleting that one line lost
# the tooling rules silently rather than failing. Its contents now live in
# CLAUDE.md directly.
mkdir -p "$HOME/.claude"
link "$DOTFILES_DIR/.claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"

# The Notification hook script. ~/.claude/settings.json points at it but is NOT
# tracked here — it is mostly state Claude writes itself — so the hook block has
# to be pasted in by hand once per machine. notify.sh's own header carries it.
mkdir -p "$HOME/.claude/hooks"
link "$DOTFILES_DIR/.claude/hooks/notify.sh" "$HOME/.claude/hooks/notify.sh"

# The status line command — the plan's 5-hour and 7-day usage windows on screen
# at all times, rather than only when /usage is asked. Same untracked-settings
# story as the hook above: the script deploys, the `statusLine` block does not.
# It lives beside hooks/ rather than inside it because Claude Code does not
# treat it as a hook — it is named by its own top-level `statusLine` setting
# rather than by an event, and it re-runs on every render, not on a lifecycle.
link "$DOTFILES_DIR/.claude/statusline.sh" "$HOME/.claude/statusline.sh"

# Skills: link every skill directory under .claude/skills. A loop rather than one
# `link` line per skill, for the same reason .config/* is a loop — a skill added
# to the repo but not named here would silently never deploy, which is exactly
# the failure mode the old @AGENTS.md import had. Claude Code discovers a skill
# by its directory holding a SKILL.md, so the directory is what gets linked, not
# the file inside it.
if [ -d "$DOTFILES_DIR/.claude/skills" ]; then
  mkdir -p "$HOME/.claude/skills"
  shopt -s dotglob nullglob
  for item in "$DOTFILES_DIR/.claude/skills"/*; do
    [ -d "$item" ] || continue
    case "$(basename "$item")" in .DS_Store) continue ;; esac
    link "$item" "$HOME/.claude/skills/$(basename "$item")"
  done
  shopt -u dotglob nullglob

  # Sweep ~/.claude/skills links left dangling by a skill this repo no longer
  # ships. Same guard as the other sweeps — only a symlink pointing into this
  # repo is removed, so a hand-installed skill from elsewhere survives.
  for item in "$HOME/.claude/skills"/*; do
    if [ -L "$item" ] && [ ! -e "$item" ] \
      && case "$(readlink "$item")" in "$DOTFILES_DIR"/*) true ;; *) false ;; esac; then
      rm -f "$item" && info "Removed dangling symlink ~/.claude/skills/$(basename "$item")"
    fi
  done
fi

# Retired: the ~/.claude/AGENTS.md link from before that merge. Same guard as the
# root-level sweep above — only a symlink pointing into this repo is removed.
if [ -L "$HOME/.claude/AGENTS.md" ] && case "$(readlink "$HOME/.claude/AGENTS.md")" in "$DOTFILES_DIR"/*) true ;; *) false ;; esac; then
  rm -f "$HOME/.claude/AGENTS.md" && info "Removed retired symlink ~/.claude/AGENTS.md"
fi

# ~/.config sub-configs: link every entry in the repo's .config. dotglob so `*`
# would also match a hidden entry (there are none today — this is defensive, so
# adding one later doesn't silently go unlinked); nullglob so an empty dir
# doesn't leave the literal glob pattern behind.
mkdir -p "$HOME/.config"
if [ -d "$DOTFILES_DIR/.config" ]; then
  shopt -s dotglob nullglob
  for item in "$DOTFILES_DIR/.config"/*; do
    [ -e "$item" ] || continue
    case "$(basename "$item")" in .DS_Store) continue ;; esac
    link "$item" "$HOME/.config/$(basename "$item")"
  done
  shopt -u dotglob nullglob

  # Sweep ~/.config links left dangling by an entry this repo no longer ships.
  for item in "$HOME/.config"/*; do
    if [ -L "$item" ] && [ ! -e "$item" ] \
      && case "$(readlink "$item")" in "$DOTFILES_DIR"/*) true ;; *) false ;; esac; then
      rm -f "$item" && info "Removed dangling symlink ~/.config/$(basename "$item")"
    fi
  done
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
title "Theme (Voltage)"
#------------------------------------------------------------------------------
# Most of the palette is plain config that the symlink step above already put in
# place (ghostty, starship, fzf, vivid, eza). Two tools compile their theme into
# a cache instead of reading the file, and need a build step here. See
# themes/voltage.md.

# bat reads ~/.cache/bat/themes.bin, not the .tmTheme — without this, $BAT_THEME
# ="Voltage" doesn't resolve and bat silently falls back to its default theme.
# This also fixes delta, which highlights through bat.
if command -v bat &>/dev/null; then
  if bat cache --build &>/dev/null && bat --list-themes 2>/dev/null | grep -q '^Voltage$'; then
    success "bat theme built (Voltage)."
  else
    warning "bat cache build failed — bat/delta will use the default theme. Retry: bat cache --build"
  fi
fi

# fast-syntax-highlighting reads .config/fsh/current_theme.zsh, which IS
# committed — so this is a refresh, not a requirement, and it is best-effort:
# `fast-theme` is a plugin function, so it only exists once zinit has actually
# finished installing fast-syntax-highlighting above.
if command -v zsh &>/dev/null; then
  if zsh -ic 'if (( $+functions[fast-theme] )); then fast-theme XDG:voltage; else exit 1; fi' &>/dev/null; then
    success "Syntax-highlighting theme applied (Voltage)."
  else
    info "Skipped fast-theme refresh; the committed current_theme.zsh already carries Voltage."
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
# Opt-in, and off by default: macos.sh rewrites system defaults, and the other
# four pull down a lot of global packages. Previously this section was five
# commented-out lines, which meant editing the installer to enable one — so it
# printed a heading and did nothing on every run. Select them by name instead:
#
#     SETUP_SCRIPTS="npm composer" ./install.sh
#     SETUP_SCRIPTS=all ./install.sh
#
# Executed directly rather than through `sh`: every script in setup/ declares a
# bash shebang and uses bash arrays, which `sh` survives only by accident on
# macOS (where /bin/sh is bash in POSIX mode) and not at all where it is dash.
SETUP_SCRIPTS="${SETUP_SCRIPTS:-}"
[ "$SETUP_SCRIPTS" = "all" ] && SETUP_SCRIPTS="macos npm composer mas gh-extensions"

if [ -z "$SETUP_SCRIPTS" ]; then
  info 'None requested — re-run with SETUP_SCRIPTS="npm composer" (or =all) to include them.'
else
  # Unquoted on purpose: the variable is a space-separated list of names.
  for s in $SETUP_SCRIPTS; do
    setup_script="$DOTFILES_DIR/setup/$s.sh"
    if [ ! -f "$setup_script" ]; then
      warning "No such setup script: $s — expected $setup_script"
    elif [ ! -x "$setup_script" ]; then
      warning "Not executable: $setup_script — run: chmod +x $setup_script"
    else
      info "Running setup/$s.sh..."
      if "$setup_script"; then
        success "setup/$s.sh finished."
      else
        warning "setup/$s.sh exited non-zero — see the output above."
      fi
    fi
  done
fi

success "\nDone. Open a new terminal (or run: exec zsh) to load the new shell."
