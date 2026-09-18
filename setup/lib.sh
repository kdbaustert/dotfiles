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
#  Touch ID and the iTerm2 prefs live in install.sh; pacman, the AUR helper and
#  fontconfig live in install-linux.sh. If a function here
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
warning() { echo -e "${COLOR_YELLOW}Warning: ${COLOR_NONE}$1"; ISSUES+=("$1"); }
info()    { echo -e "${COLOR_BLUE}Info: ${COLOR_NONE}$1"; }
success() { echo -e "${COLOR_GREEN}$1${COLOR_NONE}"; }

# spinner_run <label> <command...>
# Runs a command while a header line (spinner + elapsed seconds) plus a
# scrolling window of the command's own latest output lines redraws in place,
# so a step that would otherwise sit blank for minutes (an AUR build, a silent
# download) reads as "still going, and here's what it's doing" rather than
# "stuck". Falls back to passing output straight through when stdout isn't a
# terminal (piped/logged runs), where cursor-movement escapes would just print
# garbage.
# On failure the full log is left in place and its path printed, since a
# build failure with no output is unactionable; on success it's removed.
# Returns the command's own exit status.
spinner_run() {
  local label="$1"; shift
  local logfile
  logfile="$(mktemp)"

  if [ ! -t 1 ]; then
    info "$label"
    "$@" </dev/null 2>&1 | tee "$logfile"
    local st=${PIPESTATUS[0]}
    [ "$st" -eq 0 ] && rm -f "$logfile"
    return "$st"
  fi

  "$@" </dev/null >"$logfile" 2>&1 &
  local pid=$! frames='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏' i=0 start=$SECONDS
  local cols window=5 drawn=0
  cols=$(tput cols 2>/dev/null || echo 80)
  # Rows a printed line actually occupies once the terminal wraps it — the
  # header/tail lines are shown in full (no truncation), so a long one can
  # span more than one row and the cursor-up math below has to account for it.
  _spinner_rows() { local len=$1; ((len == 0)) && { echo 1; return; }; echo $(((len + cols - 1) / cols)); }
  while kill -0 "$pid" 2>/dev/null; do
    # Move up over whatever this loop drew last iteration, then redraw the
    # header + tail so the block updates in place instead of scrolling.
    [ "$drawn" -gt 0 ] && printf '\033[%dA' "$drawn"
    local header rows=0
    header="$(printf '%s %s (%ss)' "${frames:i%${#frames}:1}" "$label" "$((SECONDS - start))")"
    printf '\r%s\033[K\n' "$header"
    rows=$(_spinner_rows "${#header}")
    local lines=()
    while IFS= read -r line; do
      lines+=("$line")
    done < <(tail -n "$window" "$logfile" 2>/dev/null | tr -d '\r')
    for line in "${lines[@]}"; do
      printf '  %s\033[K\n' "$line"
      rows=$((rows + $(_spinner_rows $((${#line} + 2)))))
    done
    drawn=$rows
    i=$((i + 1))
    sleep 0.1
  done
  wait "$pid"
  local status=$?
  [ "$drawn" -gt 0 ] && printf '\033[%dA' "$drawn"
  printf '\033[J'
  if [ "$status" -eq 0 ]; then
    rm -f "$logfile"
  else
    warning "$label failed — full output in $logfile"
  fi
  return $status
}

# Every warning collected during the run, so a step's failure does not scroll
# off screen by the time the installer finishes. `error` is deliberately not
# collected here — its four call sites are all preconditions the rest of the
# script cannot run without, so it still exits immediately rather than joining
# a summary nobody gets to read.
ISSUES=()

# print_summary — call once, at the very end of install.sh / install-linux.sh.
print_summary() {
  if [ ${#ISSUES[@]} -eq 0 ]; then
    success "\nNo warnings — every step completed cleanly."
    return 0
  fi
  echo -e "\n${COLOR_YELLOW}${#ISSUES[@]} step(s) had warnings:${COLOR_NONE}"
  local i
  for i in "${ISSUES[@]}"; do
    echo -e "  ${COLOR_YELLOW}-${COLOR_NONE} $i"
  done
}

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
      case "$(basename "$item")" in
        .DS_Store) continue ;;
        # ghostty is the one .config entry that is not deployed everywhere.
        # The terminal is macOS-only in this setup and the config is written for
        # it — macos-titlebar-style, window-colorspace and font-thicken are all
        # no-ops in the GTK build — so linking it on Arch put a file there for a
        # terminal that is not installed. The exclusion lives here rather than
        # in a per-OS file because the rest of the loop is genuinely shared; see
        # the macOS/Linux section of CLAUDE.md for which layer takes which case.
        ghostty) [ "$os" = macos ] || continue ;;
      esac
      link "$item" "$HOME/.config/$(basename "$item")"
    done
    shopt -u dotglob nullglob
    sweep_dangling "$HOME/.config"
  fi

  # Retire a ghostty link left by a run from before that exclusion. Same guard
  # as every other sweep here: a symlink pointing into this repo and nothing
  # else, so a real directory or one someone linked from elsewhere survives.
  if [ "$os" != macos ] && [ -L "$HOME/.config/ghostty" ] \
    && case "$(readlink "$HOME/.config/ghostty")" in "$DOTFILES_DIR"/*) true ;; *) false ;; esac; then
    rm -f "$HOME/.config/ghostty" && info "Removed ~/.config/ghostty — that config is macOS-only."
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
# CLAUDE_PLUGINS
#------------------------------------------------------------------------------
# The plugin set install_claude_plugins (below) installs, declared once and
# shared by install.sh and install-linux.sh — both call
# `install_claude_plugins "${CLAUDE_PLUGINS[@]}"` rather than each carrying its
# own copy of the list. Same reasoning as link_dotfiles living here instead of
# in both installers: a list that grows over time and exists twice drifts
# silently the first time only one copy gets edited. Add a plugin by appending
# a line; each one installs as `<name>@claude-plugins-official`.
#
# shellcheck disable=SC2034 # read by install.sh and install-linux.sh after they source this file
CLAUDE_PLUGINS=(
  php-lsp          # intelephense, for cnc-claims' PHP
  swift-lsp        # SourceKit-LSP, for the Developer/ Swift projects
  typescript-lsp   # typescript-language-server, for web work
  miro             # board access via MCP; auth happens on first use, not here
  frontend-design  # design-quality guidance for new/reshaped UI work
  code-simplifier  # reuse/simplification pass over recently changed code
  atlassian        # Jira + Confluence; backs .claude/CLAUDE.md's Jira-comment workflow
  asana            # Asana task/project MCP; needs /asana-setup once, after install
  code-review      # multi-agent PR review with confidence-scored findings
)

#------------------------------------------------------------------------------
# install_claude_plugins <plugin...>
#------------------------------------------------------------------------------
# Installs each named plugin from the official marketplace
# (claude-plugins-official) by name, at user scope. Unlike everything else
# link_dotfiles puts under ~/.claude, a plugin isn't a file this repo owns —
# `claude plugin install` writes into ~/.claude/plugins/installed_plugins.json,
# which is runtime state the CLI manages itself and was never a candidate for a
# symlink (see the note above link_dotfiles's ~/.claude section). So the only
# way an install survives a fresh machine is running the command again here.
#
# Both `claude plugin marketplace add` and `claude plugin install` are
# idempotent on their own — re-adding a marketplace already on disk, or
# reinstalling a plugin already at the requested version, exits 0 with an
# "already" message rather than erroring — so this is a plain loop with no
# separate already-installed check. `-y` accepts a marketplace-declared
# command with no prompt; none of the LSP plugins declare one, but the flag
# costs nothing and keeps a future catalog change from hanging a
# non-interactive run.
#
# Guarded on the `claude` binary, not on SETUP_SCRIPTS: the CLI isn't
# installed by this repo (it's Claude Code's own installer, not the Brewfile's
# `cask "claude"`, which is the unrelated desktop app), so a fresh machine
# that hasn't run it yet skips cleanly rather than erroring the rest of the
# installer. Takes its plugin names as arguments rather than reading
# CLAUDE_PLUGINS directly, so it stays a plain, testable "install these"
# primitive — CLAUDE_PLUGINS is the one caller that matters today, not a
# hidden dependency of the function itself.
install_claude_plugins() {
  local plugin

  if ! command -v claude &>/dev/null; then
    warning "claude CLI not found — skipped Claude Code plugins ($*)."
    return 0
  fi

  claude plugin marketplace add anthropics/claude-plugins-official &>/dev/null \
    || warning "Could not add/verify the claude-plugins-official marketplace."

  for plugin in "$@"; do
    if claude plugin install "${plugin}@claude-plugins-official" -y &>/dev/null; then
      success "Claude Code plugin ${plugin}@claude-plugins-official installed."
    else
      warning "Failed to install Claude Code plugin ${plugin}@claude-plugins-official."
    fi
  done
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
