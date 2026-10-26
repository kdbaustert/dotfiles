#!/usr/bin/env bash
#==============================================================================
#  setup/lib.sh — the installer's reusable steps
#------------------------------------------------------------------------------
#  Sourced by install.sh. It is NOT executable and does nothing on its own;
#  every function here is called from one of install.sh's sections.
#
#  This used to be the half shared with a Linux installer, which is gone. It
#  stays a separate file because install.sh reads as a list of sections, and
#  ~800 lines of symlink loops and settings merges inlined into it would bury
#  that list. The split is the same as before: install.sh owns the section
#  order, the prompts and anything that talks to Homebrew, launchd or system
#  defaults; this file owns the steps those sections call.
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

# Every warning collected during the run, so a step's failure does not scroll
# off screen by the time the installer finishes. `error` is deliberately not
# collected here — every call site is a precondition the rest of the
# script cannot run without, so it still exits immediately rather than joining
# a summary nobody gets to read.
ISSUES=()

# print_summary — call once, at the very end of install.sh.
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
  # Stops when the backup fails. Going on, `ln -sfn` onto a real directory
  # puts the link inside it, and the line below used to report that as linked.
  if [ -e "$dst" ] && [ ! -L "$dst" ]; then
    if ! mv "$dst" "${dst}.backup-$(date +%Y%m%d-%H%M%S)"; then
      warning "Could not back up $dst — left it in place and did not link it."
      return
    fi
    info "Backed up existing $dst"
  fi
  if ln -sfn "$src" "$dst"; then
    success "linked  $dst → $src"
  else
    warning "Could not link $dst → $src"
  fi
}

# is_dangling_repo_link <path> — whether <path> is a symlink into this repo
# whose target is gone. Never true for a real file or for a link installed by
# hand from somewhere else; that guard is what lets the sweeps run unattended.
# The repo path is matched as typed and resolved (pwd -P), because a link made
# by an earlier run through a symlinked or differently spelled path would
# otherwise never be recognised, and its LaunchAgent never retired.
is_dangling_repo_link() {
  local target physical

  [ -L "$1" ] && [ ! -e "$1" ] || return 1
  target="$(readlink "$1")"
  physical="$(CDPATH='' cd -- "$DOTFILES_DIR" 2>/dev/null && pwd -P)"
  case "$target" in
    "$DOTFILES_DIR"/*) return 0 ;;
    "${physical:-$DOTFILES_DIR}"/*) return 0 ;;
  esac
  return 1
}

# sweep_dangling <dir> — remove the dangling repo links directly under <dir>.
sweep_dangling() {
  local item
  for item in "$1"/*; do
    if is_dangling_repo_link "$item"; then
      rm -f "$item" && info "Removed dangling symlink $item"
    fi
  done
}

# retire_launch_agents <dir> — unload and remove the LaunchAgent plists under
# <dir> that are dangling repo links. A plain sweep would delete the file and
# leave the job loaded until logout, still running whatever it was told to.
# The label is read off the file name, launchd's naming convention, since the
# file that held the Label key is the one that is gone.
retire_launch_agents() {
  local item label
  for item in "$1"/*.plist; do
    is_dangling_repo_link "$item" || continue
    label="$(basename "$item" .plist)"
    launchctl bootout "gui/$(id -u)/$label" &>/dev/null
    rm -f "$item" && info "Retired LaunchAgent $label (its plist left the repo)."
  done
}

# merge_claude_settings — merge preferences while keeping hooks and local state.
# env and skillOverrides merge key by key; replacing either would drop the
# variables or per-machine skill toggles the portable file doesn't name. A
# matching config is left alone so repeat installs do not rewrite it.
merge_claude_settings() {
  if ! command -v python3 &>/dev/null; then
    warning "Python 3 is needed to merge Claude settings."
    return
  fi

  if python3 - "$DOTFILES_DIR/.claude/settings.portable.json" "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/settings.json" <<'PYTHON'
import json
import os
from pathlib import Path
import stat
import sys
import tempfile

source, target = map(Path, sys.argv[1:])
if target.is_symlink():
    raise SystemExit("Claude settings is a symlink; refusing to modify its target.")

settings = json.loads(source.read_text())
before = json.loads(target.read_text()) if target.exists() else {}
if not isinstance(before, dict) or not isinstance(settings, dict):
    raise SystemExit("Claude settings must be JSON objects; left untouched.")
updated = {**before, **settings}
for key in ("env", "skillOverrides"):
    if key in settings:
        updated[key] = {**before.get(key, {}), **settings[key]}
if updated == before:
    raise SystemExit(0)

serialized = json.dumps(updated, indent=2) + "\n"
assert json.loads(serialized) == updated
target.parent.mkdir(parents=True, exist_ok=True)
with tempfile.NamedTemporaryFile(mode="w", dir=target.parent, delete=False) as file:
    temporary = Path(file.name)
    try:
        file.write(serialized)
        file.flush()
        if target.exists():
            os.chmod(temporary, stat.S_IMODE(target.stat().st_mode))
        os.replace(temporary, target)
    finally:
        temporary.unlink(missing_ok=True)
PYTHON
  then
    success "Claude portable settings applied."
  else
    warning "Could not merge Claude settings; existing settings left untouched."
  fi
}

# merge_codex_settings — apply portable preferences without tracking app state.
# Requires Python 3.11+ for TOML validation. A failed merge leaves config alone
# and warns rather than preventing the rest of the dotfiles from deploying.
merge_codex_settings() {
  # Checked up front so an old python3 gets this warning, not a traceback
  # followed by "Could not merge". macOS's /usr/bin/python3 is 3.9.
  if ! python3 -c 'import tomllib' &>/dev/null; then
    warning "Python 3.11+ is needed to merge Codex settings (python3 is $(command -v python3 || echo missing)); brew bundle installs it."
    return
  fi

  if python3 - "$DOTFILES_DIR/.codex/settings.toml" "${CODEX_HOME:-$HOME/.codex}/config.toml" <<'PYTHON'
import os
from pathlib import Path
import re
import stat
import sys
import tempfile
import tomllib

source, target = map(Path, sys.argv[1:])
if target.is_symlink():
    raise SystemExit("Codex config is a symlink; refusing to modify its target.")

settings_text = source.read_text()
settings = tomllib.loads(settings_text)
original = target.read_text() if target.exists() else ""
before = tomllib.loads(original)
if all(before.get(key) == value for key, value in settings.items()):
    raise SystemExit(0)

# Only remove managed root keys. TOML validation below rejects any edit that
# would accidentally change a table or a multiline string containing one.
lines = []
in_root = True
for line in original.splitlines(keepends=True):
    if line.lstrip().startswith("["):
        in_root = False
    assignment = re.match(r"^\s*([A-Za-z0-9_-]+)\s*=", line)
    if in_root and assignment and assignment[1] in settings:
        continue
    lines.append(line)

updated = settings_text.rstrip() + "\n\n" + "".join(lines)
if tomllib.loads(updated) != {**before, **settings}:
    raise SystemExit("Codex merge would change unrelated settings; left untouched.")

target.parent.mkdir(parents=True, exist_ok=True)
with tempfile.NamedTemporaryFile(mode="w", dir=target.parent, delete=False) as file:
    temporary = Path(file.name)
    try:
        file.write(updated)
        file.flush()
        if target.exists():
            os.chmod(temporary, stat.S_IMODE(target.stat().st_mode))
        os.replace(temporary, target)
    finally:
        temporary.unlink(missing_ok=True)
PYTHON
  then
    success "Codex token-saving settings applied."
  else
    warning "Could not merge Codex settings; existing config left untouched."
  fi
}

#------------------------------------------------------------------------------
# link_dotfiles
#------------------------------------------------------------------------------
# Every symlink this repo deploys.
link_dotfiles() {
  local f item

  # Root-level dotfiles (only those that exist in the repo are linked).
  # .vimrc and .default-npm-packages were dropped from this list: neither has
  # ever existed in the repo, so they warned on every single run — two
  # guaranteed warnings is exactly how you learn to stop reading them.
  for f in .zshenv .zshrc .gitconfig .editorconfig .prettierrc; do
    link "$DOTFILES_DIR/$f" "$HOME/$f"
  done

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
  # .gitconfig-os pointed at .gitconfig-macos or .gitconfig-linux, the platform
  # half of .gitconfig; with Linux support gone that half moved into .gitconfig
  # itself and both source files were deleted, so the old link now dangles.
  for f in .gitignore .eslintrc .eslintignore .stylelintrc .prettierignore \
           tsconfig.json .gitconfig-os; do
    if [ -L "$HOME/$f" ] && case "$(readlink "$HOME/$f")" in "$DOTFILES_DIR"/*) true ;; *) false ;; esac; then
      rm -f "$HOME/$f" && info "Removed retired symlink ~/$f"
    fi
  done

  # .zprofile is the zsh login file; also expose it as ~/.profile for parity.
  link "$DOTFILES_DIR/.zprofile" "$HOME/.zprofile"
  link "$DOTFILES_DIR/.zprofile" "$HOME/.profile"

  # Claude Code's global instructions. The rest of ~/.claude is state Claude
  # writes itself (settings.local.json, projects/, todos/), so the directory is
  # created and linked into, never linked over.
  #
  # Two files, split by cost. CLAUDE.md is loaded into every session in every
  # project, so it carries the rules alone. REFERENCE.md carries the
  # measurements and history behind them and is read only when CLAUDE.md sends
  # Claude there. They used to be one 29 KB file, about 7k tokens paid at the
  # start of every session and again in most subagents, most of it reasoning a
  # normal turn never needed. Not an `@REFERENCE.md` import: imports load
  # eagerly, which would put the cost straight back.
  #
  # There used to be a second file here, AGENTS.md, linked for the sake of
  # tools that DO look for it at user scope and pulled into CLAUDE.md by an
  # `@AGENTS.md` import. Claude Code never discovered it on its own — verified
  # against 2.1.231: neither ~/.claude/AGENTS.md nor <project>/AGENTS.md was
  # read, only CLAUDE.md was — so the import was the only thing loading it, and
  # deleting that one line lost the tooling rules silently rather than failing.
  # Its contents now live in CLAUDE.md directly. (2.1.310's builtin agents-md
  # plugin reads a project AGENTS.md where there is no CLAUDE.md, which is a
  # project-scope change and leaves this one alone. The repo root now uses
  # AGENTS.md with CLAUDE.md linked to it; setup/REFERENCE.md has why.)
  mkdir -p "$HOME/.claude"
  link "$DOTFILES_DIR/.claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
  link "$DOTFILES_DIR/.claude/REFERENCE.md" "$HOME/.claude/REFERENCE.md"
  merge_claude_settings

  # Codex reads the same rules. It looks for its global instructions in
  # $CODEX_HOME, AGENTS.override.md first and AGENTS.md only when the override
  # is empty or missing. The override is the one linked, because nodeterm
  # rewrites marked blocks inside ~/.codex/AGENTS.md: a link there would land
  # its ~350 lines in the tracked CLAUDE.md, the same in-place-rewrite hazard
  # as `iris setup`. The cost is that Codex stops seeing nodeterm's canvas
  # instructions while the override exists. A copy kept in a marked block of
  # its own beside nodeterm's was the other option, passed on because it goes
  # stale between installs. Two config.toml lines go with this and are manual,
  # like settings.json; CLAUDE.md carries them.
  mkdir -p "${CODEX_HOME:-$HOME/.codex}"
  link "$DOTFILES_DIR/.claude/CLAUDE.md" "${CODEX_HOME:-$HOME/.codex}/AGENTS.override.md"
  merge_codex_settings

  # The Notification hook script. ~/.claude/settings.json points at it but is
  # NOT tracked here — it is mostly state Claude writes itself — so the hook
  # block has to be pasted in by hand once per machine. notify.sh's own header
  # carries it.
  mkdir -p "$HOME/.claude/hooks"
  link "$DOTFILES_DIR/.claude/hooks/notify.sh" "$HOME/.claude/hooks/notify.sh"

  # The PreToolUse hook that rejects a widened rg/fd missing the noise-folder
  # excludes. Same manual settings.json step; its header carries the block.
  link "$DOTFILES_DIR/.claude/hooks/search-excludes.sh" \
    "$HOME/.claude/hooks/search-excludes.sh"

  # The StopFailure hook that resumes a session after the usage limit resets.
  # Same manual settings.json step; its header carries the block and explains
  # the --sweep half the usage-refresh LaunchAgent runs.
  link "$DOTFILES_DIR/.claude/hooks/resume-after-limit.sh" \
    "$HOME/.claude/hooks/resume-after-limit.sh"

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

  # Slash commands: link every command file under .claude/commands, same
  # loop-not-list reasoning as skills and agents above — a file added here but
  # not named in the installer would silently never deploy. Claude Code
  # discovers a command the same way it discovers a subagent: by a .md file
  # directly under ~/.claude/commands, so the file itself is what gets linked,
  # not a containing directory.
  if [ -d "$DOTFILES_DIR/.claude/commands" ]; then
    mkdir -p "$HOME/.claude/commands"
    shopt -s dotglob nullglob
    for item in "$DOTFILES_DIR/.claude/commands"/*.md; do
      [ -f "$item" ] || continue
      link "$item" "$HOME/.claude/commands/$(basename "$item")"
    done
    shopt -u dotglob nullglob
    sweep_dangling "$HOME/.claude/commands"
  fi

  # User-level rules: link every rule file under .claude/rules, same
  # loop-not-list reasoning as the three loops above. Claude Code loads every
  # .md file under ~/.claude/rules in every project, before the project's own
  # rules, and one with no `paths:` frontmatter loads unconditionally like
  # CLAUDE.md does. This is where a vendored ruleset goes instead of being
  # pasted into CLAUDE.md: it stays upstream's file, so a refresh is a diff
  # rather than a merge. Codex has no equivalent, so these reach Claude only.
  if [ -d "$DOTFILES_DIR/.claude/rules" ]; then
    mkdir -p "$HOME/.claude/rules"
    shopt -s dotglob nullglob
    for item in "$DOTFILES_DIR/.claude/rules"/*.md; do
      [ -f "$item" ] || continue
      link "$item" "$HOME/.claude/rules/$(basename "$item")"
    done
    shopt -u dotglob nullglob
    sweep_dangling "$HOME/.claude/rules"
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
# tools g-prefixed and gnubin is off PATH by design). .zshrc runs the database
# through `gdircolors` itself.
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
# sync_atuin_daemon <plist> <binary>
#------------------------------------------------------------------------------
# Keeps atuin's launchd daemon on the same binary the zsh hooks call. Since
# 18.24 the daemon refuses a client from a different build ("daemon is build
# 18.24.2, client sent no build"), and the hooks send `atuin history end`'s
# stderr to /dev/null, so a mismatch stops history from recording with no
# message anywhere. That happened on 2026-10-23 and went unnoticed for three
# days: a Homebrew atuin landed beside zinit's, and autostart wrote the plist
# with whichever binary started the daemon first. atuin is Homebrew-only now
# (homebrew/Brewfile), but autostart still writes whatever binary it ran from,
# and 18.24 has no `atuin daemon install` to regenerate the plist, so this
# edits its ProgramArguments in place.
#
# Other atuin binaries on PATH are only reported, not removed. One of them is
# how the plist drifts, but uninstalling a package is the user's call.
#
# Arguments:
#   $1  the daemon's LaunchAgent plist; skipped when missing, because autostart
#       writes it the first time a shell needs the daemon
#   $2  the atuin binary the shell hooks resolve: Homebrew's bin link
sync_atuin_daemon() {
  local plist="$1" binary="$2"
  local current label other

  if [ ! -x "$binary" ]; then
    warning "Skipping atuin daemon check — atuin not found at $binary (brew bundle installs it)."
    return 0
  fi

  while IFS= read -r other; do
    [ "$other" = "$binary" ] && continue
    warning "Second atuin at $other — remove it so only one build talks to the daemon."
  done < <(type -ap atuin)

  if [ ! -f "$plist" ]; then
    info "No atuin daemon agent yet — autostart writes it on first use."
    return 0
  fi

  current="$(/usr/libexec/PlistBuddy -c 'Print :ProgramArguments:0' "$plist" 2>/dev/null)"
  if [ "$current" = "$binary" ]; then
    info "atuin daemon already runs $binary."
    return 0
  fi

  info "atuin daemon runs ${current:-nothing}; pointing it at $binary..."
  label="$(/usr/libexec/PlistBuddy -c 'Print :Label' "$plist")"
  /usr/libexec/PlistBuddy -c "Set :ProgramArguments:0 $binary" "$plist"

  # bootstrap can report "5: Input/output error" while launchd is still tearing
  # down the job bootout just stopped, even though the new one loads. So the
  # check reads the running program back instead of trusting either exit code.
  launchctl bootout "gui/$(id -u)/$label" &>/dev/null
  launchctl bootstrap "gui/$(id -u)" "$plist" &>/dev/null
  if launchctl print "gui/$(id -u)/$label" 2>/dev/null | grep -qF "program = $binary"; then
    success "atuin daemon now runs $binary."
  else
    warning "atuin daemon plist updated but not reloaded — run: launchctl kickstart -k gui/$(id -u)/$label"
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
# Command correction (the `fuck` alias in .zshrc). Not installed from Homebrew:
# there is no core formula, and the tap upstream points at is a third-party repo pinning `version "nightly"` — a
# moving target for a tool that reads the command line. So: pull the author's
# own signed release, pinned and checksummed, into ~/.local/bin (already on PATH
# via .zprofile).
#
# The release only ships .tar.zst, which is why this isn't a zinit `gh-r` block
# like starship was — zinit's extractor handles zip/tar.gz/tar.xz/7z, not zstd.
#
# Asset name and checksum are the caller's to supply because they change with
# every version bump and with the architecture; install.sh pins both next to the
# arm64 check that picks the asset.
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
# The plugin set install_claude_plugins (below) installs; install.sh's claude
# section calls `install_claude_plugins "${CLAUDE_PLUGINS[@]}"`. Add a plugin by
# appending a line; a bare name installs as `<name>@claude-plugins-official`.
#
# A plugin from anywhere else is written `<name>@<owner>/<repo>`: the GitHub
# repo is its marketplace, added first, and the plugin installs as
# `<name>@<repo>`. That leans on the marketplace's own `name` (in its
# .claude-plugin/marketplace.json) matching the repo's — true of every
# marketplace here, the official one included — because `claude plugin
# marketplace add` reports nothing machine-readable to learn the name from
# (no --json, checked on 2.1.285). A marketplace that breaks the convention
# fails loudly as a "Failed to install" warning, not silently.
#
# shellcheck disable=SC2034 # read by install.sh after it sources this file
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

  # Third-party; opt-in twice over — /i-have-adhd per session, or every session
  # once ~/.claude/.i-have-adhd-always exists (its SessionStart hook checks).
  i-have-adhd@ayghri/i-have-adhd  # action-first, ADHD-shaped output style
)

#------------------------------------------------------------------------------
# install_claude_plugins <plugin...>
#------------------------------------------------------------------------------
# Installs each named plugin at user scope — a bare name from the official
# marketplace (claude-plugins-official), a `<name>@<owner>/<repo>` from that
# GitHub repo's own marketplace (see CLAUDE_PLUGINS above).
#
# Unlike everything else link_dotfiles puts under ~/.claude, a plugin isn't a
# file this repo owns —
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
# non-interactive run. For a third-party entry that is no wider trust than
# listing it at all: installing any plugin already runs its hooks as you.
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
  local entry plugin repo marketplace

  if ! command -v claude &>/dev/null; then
    warning "claude CLI not found — skipped Claude Code plugins ($*)."
    return 0
  fi

  claude plugin marketplace add anthropics/claude-plugins-official &>/dev/null \
    || warning "Could not add/verify the claude-plugins-official marketplace."

  for entry in "$@"; do
    plugin=${entry%%@*}
    marketplace=claude-plugins-official

    if [[ $entry == *@*/* ]]; then
      repo=${entry#*@}
      marketplace=${repo##*/}
      claude plugin marketplace add "$repo" &>/dev/null \
        || warning "Could not add/verify the ${marketplace} marketplace (${repo})."
    fi

    if claude plugin install "${plugin}@${marketplace}" -y &>/dev/null; then
      success "Claude Code plugin ${plugin}@${marketplace} installed."
    else
      warning "Failed to install Claude Code plugin ${plugin}@${marketplace}."
    fi
  done
}

#------------------------------------------------------------------------------
# run_setup_scripts <default-list>
#------------------------------------------------------------------------------
# Opt-in, and off by default: these pull down a lot of global packages.
# (macos.sh, which rewrites system defaults, used to be one of them and is now
# install.sh's own `macos` section.) Previously this was five
# commented-out lines in install.sh, which meant editing the installer to enable
# one — so it printed a heading and did nothing on every run. Select them by
# name instead:
#
#     SETUP_SCRIPTS="pnpm composer" ./install.sh
#     SETUP_SCRIPTS=all ./install.sh
#
# <default-list> is what `all` expands to. It is the caller's rather than a
# glob of setup/*.sh because setup/ also holds scripts that are not optional
# extras: check-agents-md.sh, check-memory-bank.sh, and macos.sh and hosts.sh,
# which install.sh runs as sections of their own.
#
# Executed directly rather than through `sh`: every script in setup/ declares a
# bash shebang and uses bash arrays, which `sh` survives only by accident on
# macOS, where /bin/sh is bash in POSIX mode.
run_setup_scripts() {
  local all_list="$1" s setup_script
  local requested="${SETUP_SCRIPTS:-}"
  [ "$requested" = "all" ] && requested="$all_list"

  if [ -z "$requested" ]; then
    info "None requested — re-run with SETUP_SCRIPTS=\"pnpm composer\" (or =all) to include them."
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
