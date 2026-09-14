#!/usr/bin/env bash
#==============================================================================
#  setup/lib.sh — the parts of the installer that are the same on every machine
#------------------------------------------------------------------------------
#  Sourced by install.sh (macOS) and install-linux.sh (Arch/Manjaro). It is NOT
#  executable and does nothing on its own; every function here is called by one
#  of those two.
#
#  Why a library rather than two self-contained installers: the symlink section
#  alone is ~120 lines and changes every time a skill, an agent or a .config
#  entry is added. Two copies of it would drift within a week, and the failure
#  mode is the silent one this repo keeps running into — a new skill deploys on
#  one machine and simply never appears on the other, with nothing to notice.
#  The same argument the palette doc makes about hex values applies here.
#
#  What stays OUT of this file: anything a package manager, an OS service or a
#  system path makes specific to one platform. Homebrew, Nix's Darwin notes,
#  Touch ID, the iTerm2 prefs and the tab-icon font live in install.sh; pacman,
#  the AUR helper and fontconfig live in install-linux.sh. If a function here
#  ever needs an `if macos` inside it, that is the signal it belongs to the
#  callers instead.
#
#  Callers must set DOTFILES_DIR before sourcing.
#==============================================================================

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

# Remove a symlink that points into this repo and is now dangling. Never
# touches a real file, and never touches a link installed by hand from
# somewhere else — that guard is what lets the sweeps run unattended.
sweep_dangling() {
  local item
  for item in "$1"/*; do
    if [ -L "$item" ] && [ ! -e "$item" ] \
      && case "$(readlink "$item")" in "$DOTFILES_DIR"/*) true ;; *) false ;; esac; then
      rm -f "$item" && info "Removed dangling symlink $item"
    fi
  done
}

#------------------------------------------------------------------------------
# link_dotfiles <os>
#------------------------------------------------------------------------------
# Every symlink this repo deploys. <os> is `macos` or `linux` and selects the
# .gitconfig-os target — see the [include] in .gitconfig for why that one
# setting cannot be a runtime branch like the shell files use.
link_dotfiles() {
  local os="$1" f item

  # Root-level dotfiles (only those that exist in the repo are linked).
  # .vimrc and .default-npm-packages were dropped from this list: neither has
  # ever existed in the repo, so they warned on every single run — two
  # guaranteed warnings is exactly how you learn to stop reading them.
  for f in .zshenv .zshrc .gitconfig .editorconfig .prettierrc; do
    link "$DOTFILES_DIR/$f" "$HOME/$f"
  done

  # The platform half of .gitconfig, pulled in by its [include]. Both source
  # files are tracked; only one is ever linked on a given machine.
  link "$DOTFILES_DIR/.gitconfig-$os" "$HOME/.gitconfig-os"

  # The work identity that .gitconfig's includeIf pulls in for bitbucket
  # remotes, plus the allowed-signers file it points
  # gpg.ssh.allowedSignersFile at. Neither is in this repo and neither should
  # be: nothing about the work account belongs in something pushed to GitHub.
  # They are only ever warned about, never created — the contents are not ours
  # to write.
  #
  # Worth a check because the failure is silent. Git ignores a missing include
  # path rather than erroring (measured: `git config --get user.email` exits 0
  # and returns the base identity), so on a machine without these files a
  # bitbucket repo does not complain — it just commits as the personal
  # identity, signed with the personal key, which the work account cannot
  # attribute.
  #
  # Silent when they are present, on purpose. See the .vimrc note above: a line
  # that prints on every clean run is a line you stop reading.
  for f in .gitconfig-work .gitconfig-work-signers; do
    [ -e "$HOME/$f" ] || warning "Missing ~/$f — bitbucket repos will commit as the personal identity until it exists."
  done

  # Retired links, removed on re-run. Only ever unlinks a SYMLINK whose target
  # is inside $DOTFILES_DIR — a real file of the same name is left alone.
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
  # There used to be a second file here, AGENTS.md, linked for the sake of
  # tools that DO look for it at user scope and pulled into CLAUDE.md by an
  # `@AGENTS.md` import. Claude Code never discovered it on its own — verified
  # against 2.1.231: neither ~/.claude/AGENTS.md nor <project>/AGENTS.md is
  # read, only CLAUDE.md is — so the import was the only thing loading it, and
  # deleting that one line lost the tooling rules silently rather than failing.
  # Its contents now live in CLAUDE.md directly.
  mkdir -p "$HOME/.claude"
  link "$DOTFILES_DIR/.claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"

  # The Notification hook script. ~/.claude/settings.json points at it but is
  # NOT tracked here — it is mostly state Claude writes itself — so the hook
  # block has to be pasted in by hand once per machine. notify.sh's own header
  # carries it.
  mkdir -p "$HOME/.claude/hooks"
  link "$DOTFILES_DIR/.claude/hooks/notify.sh" "$HOME/.claude/hooks/notify.sh"

  # The status line command — the plan's 5-hour and 7-day usage windows on
  # screen at all times, rather than only when /usage is asked. Same
  # untracked-settings story as the hook above: the script deploys, the
  # `statusLine` block does not. It lives beside hooks/ rather than inside it
  # because Claude Code does not treat it as a hook — it is named by its own
  # top-level `statusLine` setting rather than by an event, and it re-runs on
  # every render, not on a lifecycle.
  link "$DOTFILES_DIR/.claude/statusline.sh" "$HOME/.claude/statusline.sh"

  # Skills: link every skill directory under .claude/skills. A loop rather than
  # one `link` line per skill, for the same reason .config/* is a loop — a
  # skill added to the repo but not named here would silently never deploy,
  # which is exactly the failure mode the old @AGENTS.md import had. Claude
  # Code discovers a skill by its directory holding a SKILL.md, so the
  # directory is what gets linked, not the file inside it.
  if [ -d "$DOTFILES_DIR/.claude/skills" ]; then
    mkdir -p "$HOME/.claude/skills"
    shopt -s dotglob nullglob
    for item in "$DOTFILES_DIR/.claude/skills"/*; do
      [ -d "$item" ] || continue
      case "$(basename "$item")" in .DS_Store) continue ;; esac
      link "$item" "$HOME/.claude/skills/$(basename "$item")"
    done
    shopt -u dotglob nullglob
    sweep_dangling "$HOME/.claude/skills"
  fi

  # Subagents: link every subagent file under .claude/agents, same
  # loop-not-list reasoning as skills above — a file added here but not named
  # in the installer would silently never deploy. Claude Code discovers a
  # subagent by a .md file directly under ~/.claude/agents, so the file itself
  # is what gets linked, not a containing directory.
  if [ -d "$DOTFILES_DIR/.claude/agents" ]; then
    mkdir -p "$HOME/.claude/agents"
    shopt -s dotglob nullglob
    for item in "$DOTFILES_DIR/.claude/agents"/*.md; do
      [ -f "$item" ] || continue
      link "$item" "$HOME/.claude/agents/$(basename "$item")"
    done
    shopt -u dotglob nullglob
    sweep_dangling "$HOME/.claude/agents"
  fi

  # Retired: the ~/.claude/AGENTS.md link from before that merge. Same guard as
  # the root-level sweep above — only a symlink pointing into this repo is
  # removed.
  if [ -L "$HOME/.claude/AGENTS.md" ] && case "$(readlink "$HOME/.claude/AGENTS.md")" in "$DOTFILES_DIR"/*) true ;; *) false ;; esac; then
    rm -f "$HOME/.claude/AGENTS.md" && info "Removed retired symlink ~/.claude/AGENTS.md"
  fi

  # ~/.config sub-configs: link every entry in the repo's .config. dotglob so
  # `*` would also match a hidden entry (there are none today — this is
  # defensive, so adding one later doesn't silently go unlinked); nullglob so
  # an empty dir doesn't leave the literal glob pattern behind.
  mkdir -p "$HOME/.config"
  if [ -d "$DOTFILES_DIR/.config" ]; then
    shopt -s dotglob nullglob
    for item in "$DOTFILES_DIR/.config"/*; do
      [ -e "$item" ] || continue
      case "$(basename "$item")" in .DS_Store) continue ;; esac
      link "$item" "$HOME/.config/$(basename "$item")"
    done
    shopt -u dotglob nullglob
    sweep_dangling "$HOME/.config"
  fi
}

#------------------------------------------------------------------------------
# install_ls_colors
#------------------------------------------------------------------------------
# A second LS_COLORS database, kept ALONGSIDE the vivid/Voltage one rather than
# replacing it: .zshrc chooses between them at runtime via $LS_COLORS_SOURCE,
# which defaults to vivid. See that block for why Voltage stays the default.
#
# Cloned, not fetched as a release: upstream publishes no tarball. Only the
# LS_COLORS data file is used — its lscolors.sh wrapper is ignored, because it
# hardcodes `dircolors`, which does not exist on macOS (coreutils installs GNU
# tools g-prefixed and gnubin is off PATH by design). On Arch the unprefixed
# name is the right one and .zshrc's probe already prefers it, so this function
# is genuinely identical on both platforms.
#
# Deliberately NOT a zinit plugin. Everything zinit loads is turbo-deferred to
# after the first prompt, but LS_COLORS has to exist before the
# `zstyle ':completion:*' list-colors` line in .zshrc reads it.
install_ls_colors() {
  local dir="${XDG_DATA_HOME:-$HOME/.local/share}/LS_COLORS"
  local cache="${ZSH_CACHE_DIR:-$HOME/.cache/zsh}/init/trapd00r-ls-colors.zsh"

  if [ -d "$dir/.git" ]; then
    info "LS_COLORS already cloned — updating."
    if git -C "$dir" pull --quiet --ff-only 2>/dev/null; then
      success "LS_COLORS updated."
    else
      warning "LS_COLORS update failed — keeping the existing clone."
    fi
  else
    info "Cloning trapd00r/LS_COLORS..."
    if git clone --quiet --depth=1 https://github.com/trapd00r/LS_COLORS "$dir"; then
      success "LS_COLORS cloned to $dir."
    else
      warning "LS_COLORS clone failed — .zshrc falls back to vivid/Voltage."
    fi
  fi

  # zcache keys off the *binary's* mtime (dircolors), so a changed database is
  # invisible to it and a pull above would otherwise keep serving the old
  # colours forever. Dropping the cache file here is what makes the installer a
  # complete update path; `zcache_clear` remains the manual equivalent.
  if [ -f "$cache" ]; then
    rm -f "$cache" "$cache.zwc" \
      && info "Dropped the trapd00r LS_COLORS cache — it rebuilds on next shell start."
  fi
}

#------------------------------------------------------------------------------
# bootstrap_zinit
#------------------------------------------------------------------------------
# zinit.zsh self-installs on first interactive shell, but cloning here keeps the
# very first terminal clean and lets us pre-compile the plugins.
bootstrap_zinit() {
  local home="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"

  if [ ! -f "$home/zinit.zsh" ]; then
    info "Cloning zinit..."
    mkdir -p "$(dirname "$home")"
    git clone -q --depth=1 https://github.com/zdharma-continuum/zinit "$home" \
      && success "zinit installed." || warning "zinit clone failed — it will retry on first shell."
  else
    info "zinit already present."
  fi

  # Launch a zsh once so zinit installs the declared plugins.
  #
  # Every plugin is turbo-deferred (`wait lucid`), so they are scheduled rather
  # than loaded — a plain `zsh -ic exit` would exit before any of them
  # downloads. This used to be handled with `sleep 3`, which is wrong in both
  # directions: too short on a cold cache or slow link (plugins clone from
  # GitHub), and three wasted seconds when they are already installed.
  #
  # zinit exposes the scheduler directly for exactly this case:
  # `@zinit-scheduler burst` marks every queued task as timed-out and runs them
  # one by one, which is documented upstream as the way to "run package
  # installations from script, not from prompt". It returns when the queue is
  # genuinely drained.
  command -v zsh >/dev/null 2>&1 || return 0
  info "Installing zsh plugins (first run clones from GitHub — may take a moment)..."
  if zsh -ic '
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
}

#------------------------------------------------------------------------------
# build_themes
#------------------------------------------------------------------------------
# Most of the Voltage palette is plain config that the symlink step already put
# in place (ghostty, starship, fzf, vivid, eza). Two tools compile their theme
# into a cache instead of reading the file, and need a build step. See
# themes/voltage.md.
build_themes() {
  # bat reads ~/.cache/bat/themes.bin, not the .tmTheme — without this,
  # $BAT_THEME="Voltage" doesn't resolve and bat silently falls back to its
  # default theme. This also fixes delta, which highlights through bat.
  if command -v bat >/dev/null 2>&1; then
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
  if command -v zsh >/dev/null 2>&1; then
    if zsh -ic 'if (( $+functions[fast-theme] )); then fast-theme XDG:voltage; else exit 1; fi' &>/dev/null; then
      success "Syntax-highlighting theme applied (Voltage)."
    else
      info "Skipped fast-theme refresh; the committed current_theme.zsh already carries Voltage."
    fi
  fi
}

#------------------------------------------------------------------------------
# install_pay_respects <version> <sha256> <asset>
#------------------------------------------------------------------------------
# Command correction (the `fuck` alias in .zshrc). Not installed from a system
# package manager on either platform: there is no Homebrew core formula, and the
# tap upstream points at is a third-party repo pinning `version "nightly"` — a
# moving target for a tool that reads the command line. So: pull the author's
# own signed release, pinned and checksummed, into ~/.local/bin (already on PATH
# via .zprofile).
#
# The release only ships .tar.zst, which is why this isn't a zinit `gh-r` block
# like starship was — zinit's extractor handles zip/tar.gz/tar.xz/7z, not zstd.
#
# Asset name and checksum are the caller's to supply because they are per
# platform and per architecture; everything else about the install is identical.
install_pay_respects() {
  local version="$1" sha256="$2" asset="$3"
  local url="https://github.com/iffse/pay-respects/releases/download/v${version}/${asset}"
  local tmp

  if [ -x "$HOME/.local/bin/pay-respects" ] \
    && [ "$("$HOME/.local/bin/pay-respects" --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')" = "$version" ]; then
    info "pay-respects ${version} already installed."
    return 0
  fi
  if ! command -v unzstd >/dev/null 2>&1; then
    warning "Skipping pay-respects — unzstd not found (expected from the zstd package)."
    return 0
  fi

  info "Installing pay-respects ${version}..."
  tmp="$(mktemp -d)"
  if curl -sSfL -o "$tmp/$asset" "$url" \
    && echo "${sha256}  ${tmp}/${asset}" | shasum -a 256 -c - >/dev/null 2>&1 \
    && tar --use-compress-program=unzstd -xf "$tmp/$asset" -C "$tmp"; then
    mkdir -p "$HOME/.local/bin" "$HOME/.local/share/man/man1" "$HOME/.local/share/man/man5"
    install -m 755 "$tmp/pay-respects" "$HOME/.local/bin/"
    # Rules module only. _pay-respects-fallback-100-request-ai is deliberately
    # NOT installed — it ships failed commands off the machine to an AI endpoint.
    install -m 755 "$tmp/_pay-respects-module-100-runtime-rules" "$HOME/.local/bin/"
    install -m 644 "$tmp"/man/*.1 "$HOME/.local/share/man/man1/" 2>/dev/null
    install -m 644 "$tmp"/man/*.5 "$HOME/.local/share/man/man5/" 2>/dev/null
    success "pay-respects ${version} installed."
  else
    warning "pay-respects install failed (download, checksum, or extract) — skipping."
  fi
  rm -rf "$tmp"
}

#------------------------------------------------------------------------------
# run_setup_scripts <default-list>
#------------------------------------------------------------------------------
# Opt-in, and off by default: these pull down a lot of global packages, and on
# macOS one of them rewrites system defaults. Previously this was five
# commented-out lines in install.sh, which meant editing the installer to enable
# one — so it printed a heading and did nothing on every run. Select them by
# name instead:
#
#     SETUP_SCRIPTS="npm composer" ./install.sh
#     SETUP_SCRIPTS=all ./install.sh
#
# <default-list> is what `all` expands to, and it differs per platform: macos.sh
# and mas.sh have no meaning on Arch.
#
# Executed directly rather than through `sh`: every script in setup/ declares a
# bash shebang and uses bash arrays, which `sh` survives only by accident on
# macOS (where /bin/sh is bash in POSIX mode) and not at all where it is dash.
run_setup_scripts() {
  local all_list="$1" s setup_script
  local requested="${SETUP_SCRIPTS:-}"
  [ "$requested" = "all" ] && requested="$all_list"

  if [ -z "$requested" ]; then
    info "None requested — re-run with SETUP_SCRIPTS=\"npm composer\" (or =all) to include them."
    return 0
  fi

  # Unquoted on purpose: the variable is a space-separated list of names.
  # shellcheck disable=SC2086
  for s in $requested; do
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
}
