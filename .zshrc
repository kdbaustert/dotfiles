#!/usr/bin/env zsh


#==============================================================================
#  .zshrc — interactive shell configuration
#  Login/environment setup lives in .zprofile; this file is interactive-only.
#==============================================================================

# $DOTFILES is exported by .zshenv (sourced for every zsh). Keep a defensive
# fallback in case this file is ever sourced without it.
: "${DOTFILES:=$HOME/dotfiles}"

#------------------------------------------------------------------------------
# History
#------------------------------------------------------------------------------
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000000
SAVEHIST=10000000

setopt EXTENDED_HISTORY        # record timestamp of each command
setopt HIST_EXPIRE_DUPS_FIRST  # trim duplicates first when HISTFILE overflows
setopt HIST_IGNORE_ALL_DUPS    # never store a duplicate of an existing entry
setopt HIST_IGNORE_SPACE       # don't record commands that start with a space
setopt HIST_REDUCE_BLANKS      # strip superfluous whitespace before recording
setopt HIST_SAVE_NO_DUPS       # don't write duplicate entries to the history file
setopt HIST_VERIFY             # expand history, but let me confirm before running
setopt SHARE_HISTORY           # share history live across sessions (implies INC_APPEND)

#------------------------------------------------------------------------------
# Shell options
#------------------------------------------------------------------------------
setopt AUTOCD                  # `dir` == `cd dir`
setopt AUTO_PUSHD              # cd maintains a dir stack; `cd -<TAB>` to revisit
setopt PUSHD_IGNORE_DUPS       # no duplicate entries on the dir stack
setopt PUSHD_SILENT            # don't print the stack after each pushd/popd
setopt EXTENDED_GLOB           # ^, ~, # glob operators (negation, exclusion, etc.)
setopt INTERACTIVE_COMMENTS    # allow # comments at the interactive prompt
setopt ALWAYS_TO_END           # move cursor to word end after completion
setopt COMPLETE_IN_WORD        # complete from the cursor, not just the word end
setopt PATH_DIRS               # path-search command names containing slashes
setopt GLOB_DOTS               # include dotfiles in globbing
setopt HASH_LIST_ALL           # hash the command path before first completion
setopt LIST_PACKED             # use compact, variable-width completion columns
setopt NO_AUTO_MENU            # require a second TAB to open the menu
setopt NO_BEEP                 # no audible bell
setopt NO_LIST_BEEP            # no bell on ambiguous completion
setopt NOTIFY                  # report background-job status immediately
setopt NO_BG_NICE              # don't re-nice background jobs
setopt NO_HUP                  # don't HUP running jobs on exit
setopt NO_CHECK_JOBS           # don't warn about background jobs on exit
unsetopt CASE_GLOB             # case-insensitive globbing
unsetopt CORRECT               # no command auto-correction (it gets in the way)

WORDCHARS=${WORDCHARS//[\/]}   # treat / as a word boundary (e.g. for ^W)

autoload -Uz colors && colors

#------------------------------------------------------------------------------
# Keybindings (emacs-style)
#------------------------------------------------------------------------------
bindkey -e
bindkey '^U' backward-kill-line

# Ctrl-X Ctrl-E — open the current command line in $EDITOR (nvim); on save it
# runs. Invaluable for long/multiline commands.
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^X^E' edit-command-line

#------------------------------------------------------------------------------
# Init caching — `zcache` / `zcache_value`, used throughout this file
#------------------------------------------------------------------------------
# Must come before the first zcache call. Turns `eval "$(tool init zsh)"` into a
# cached `source`, removing seven serial subprocesses from startup. See the file
# for how invalidation works (binary mtime) and `zcache_clear` to force a rebuild.
source "$DOTFILES/zsh/extra/cache.zsh"

#------------------------------------------------------------------------------
# Prompt (starship) — first, so the prompt is ready before anything optional
#------------------------------------------------------------------------------
# PROMPT and RPROMPT come out of `starship init zsh` single-quoted, so they run
# starship once per prompt — correct, and why editing starship.toml takes effect
# without clearing this cache. PROMPT2 (the continuation prompt, shown only after
# an unterminated quote or a trailing `\`) is the odd one out: upstream emits it
# *double*-quoted, so it forks and execs starship at source time — on every shell
# start — to build a string most sessions never display. That single subprocess
# was ~4.2ms, the largest remaining item in `zprof`.
#
# Re-quoting it makes it behave like the other two: expanded by PROMPT_SUBST at
# the moment it's drawn. Config stays live and the fork only happens if a
# continuation prompt is actually shown.
#
# Done as a cache filter rather than an override after the fact because sourcing
# the cache is itself what pays the cost — reassigning PROMPT2 afterwards would
# be too late. Runs once per regeneration; see zcache in zsh/extra/cache.zsh.
setopt PROMPT_SUBST   # required for the lazy form below; zinit.zsh also sets it
zcache_post_starship() { sed "s|^PROMPT2=\"\\\$(\(.*\))\"\$|PROMPT2='\$(\1)'|" }
zcache starship starship init zsh

#------------------------------------------------------------------------------
# Syntax-highlighting theme location
#------------------------------------------------------------------------------
# fast-syntax-highlighting's state dir. Must be set BEFORE zinit loads the
# plugin below, because the plugin reads it at source time and defaults it to
# ${XDG_CACHE_HOME:-~/.cache}/fast-syntax-highlighting — a cache dir, i.e. not
# in this repo and not reproducible on a new machine. Pointing it here is what
# makes .config/fsh/current_theme.zsh (the applied Voltage theme, generated
# from voltage.ini by `fast-theme XDG:voltage`) load automatically on every box.
export FAST_WORK_DIR="$HOME/.config/fsh"

#------------------------------------------------------------------------------
# Plugins (zinit) — completions, autosuggestions, highlighting (all turbo)
#------------------------------------------------------------------------------
[ -f "$DOTFILES/zsh/zinit.zsh" ] && source "$DOTFILES/zsh/zinit.zsh"

#------------------------------------------------------------------------------
# Completion styling
#------------------------------------------------------------------------------
source "$DOTFILES/zsh/extra/completion.zsh"

# LS_COLORS via vivid — colorizes the completion menu (and fzf-tab previews).
# `voltage` is this repo's own theme (.config/vivid/themes/voltage.yml), not a
# vivid built-in; vivid resolves a bare name against ~/.config/vivid/themes
# first, and install.sh symlinks .config/vivid there.
# Cached: vivid re-generates the same ~2KB string every start otherwise. Change
# the theme here — or edit the theme file — and run `zcache_clear`; mtime
# invalidation only sees a new vivid binary, not new arguments or a new theme.
zcache_value vivid-ls-colors LS_COLORS vivid generate voltage
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# fzf-tab tweaks
zstyle ':completion:*:git-checkout:*' sort false           # keep git ref order
zstyle ':fzf-tab:*' switch-group ',' '.'                   # cycle groups with , / .

# No group-header row above the candidate list. 'quiet' returns early from
# lib/-ftb-generate-header, which leaves $_ftb_groups intact so $group is still
# available to fzf-preview commands and binds. Don't use 'none' for this: it
# rewrites the group names to "__hide__<n>", which would leak into $group.
zstyle ':fzf-tab:*' show-group quiet

# Accept the highlighted candidate and immediately re-complete, so a deep path
# can be walked with one Tab and then '/' per segment. This is fzf-tab's own
# default (lib/-ftb-fzf falls back to '/' off-cygwin) — pinned here so it's
# visible next to switch-group, which owns ',' and '.'.
# Trade-off: '/' can no longer be typed into the fzf query to narrow matches.
zstyle ':fzf-tab:*' continuous-trigger '/'

# Taller completion menu. fzf-tab sizes itself as
#   min(max(candidates + fzf-pad, fzf-min-height), LINES / 3 * 2)
# so it will never exceed two-thirds of the screen, and `fzf-min-height` can't
# lift that ceiling. Worse, lib/-ftb-fzf:89 writes the result through
# ${FZF_TMUX_HEIGHT:=...} without declaring the variable local, so the FIRST
# completion of the session pins that row count globally and every later menu
# reuses it regardless of candidate count or window size.
# Overriding via fzf-flags avoids both: they're appended last (lib/-ftb-fzf:97)
# and fzf resolves duplicate options in favour of the later one.
# NB: fzf-flags is most-specific-wins, NOT merged — every context below that
# sets its own fzf-flags has to repeat $_ftb_height or it falls back to the
# pinned default. Change the height here, in one place.
_ftb_height='--height=80%'
zstyle ':fzf-tab:*' fzf-flags $_ftb_height

# fzf-tab previews — show context for the candidate under the cursor
zstyle ':fzf-tab:complete:cd:*'                fzf-preview 'eza -1 --color=always --icons --group-directories-first $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*'        fzf-preview 'eza -1 --color=always --icons --group-directories-first $realpath'

# Command position (incl. aliases/functions): show what the candidate resolves
# to — `command -V` prints "x is an alias for …" / "… is a shell function" / path.
zstyle ':fzf-tab:complete:-command-:*'         fzf-preview 'command -V $word 2>/dev/null | head -20 || echo $word'
zstyle ':fzf-tab:complete:-command-:*'         fzf-flags $_ftb_height '--preview-window=down:3:wrap'
zstyle ':fzf-tab:complete:(cat|bat|less|nvim|vim|vi|nano):*' \
                                               fzf-preview 'bat --color=always --style=numbers --line-range=:200 $realpath 2>/dev/null || eza -1 --color=always $realpath'
zstyle ':fzf-tab:complete:(-command-|export|unset):*' \
                                               fzf-preview 'echo ${(P)word}'        # env-var values
zstyle ':fzf-tab:complete:(kill|ps):argument-rest:*' \
                                               fzf-preview 'ps -p $word -o comm= -o args 2>/dev/null'
zstyle ':fzf-tab:complete:(kill|ps):argument-rest:*' fzf-flags $_ftb_height '--preview-window=down:3:wrap'
unset _ftb_height
zstyle ':fzf-tab:complete:(ssh|scp|sftp):*'    fzf-preview 'dig +short $word 2>/dev/null'
zstyle ':fzf-tab:complete:git-(add|diff|restore|checkout|stash):*' \
                                               fzf-preview 'git diff --color=always $word 2>/dev/null | delta'
zstyle ':fzf-tab:complete:git-(log|show):*'    fzf-preview 'git show --color=always $word 2>/dev/null | delta'

#------------------------------------------------------------------------------
# fzf — fuzzy finder
#------------------------------------------------------------------------------
[ -f "$DOTFILES/zsh/extra/fzf.zsh" ] && source "$DOTFILES/zsh/extra/fzf.zsh"
# Ctrl-T (files) and Alt-C (cd) keybindings + completion. Ctrl-R is owned by atuin.
zcache fzf fzf --zsh

export FZF_COMPLETION_TRIGGER=','
export _ZO_FZF_OPTS="$FZF_DEFAULT_OPTS --height=45%"   # zoxide's `zi` picker
export FUNCNEST=5000

#------------------------------------------------------------------------------
# Functions & aliases
#------------------------------------------------------------------------------
source "$DOTFILES/zsh/functions.zsh"
source "$DOTFILES/zsh/aliases.zsh"

# terminal-notifier: ping when a long command finishes while Rio is unfocused
[ -f "$DOTFILES/zsh/extra/notify.zsh" ] && source "$DOTFILES/zsh/extra/notify.zsh"

# OSC 7: tell the terminal our cwd, so new tabs/splits open in the same place.
# Authoritative, unlike the process-inspection guess iTerm2 and Rio fall back to.
[ -f "$DOTFILES/zsh/extra/osc7.zsh" ] && source "$DOTFILES/zsh/extra/osc7.zsh"

# auto-ls: list the directory on every cd/pushd/z. Sourced after aliases.zsh so
# $commands[eza] is already populated; the hook itself never fires until the
# first directory change, so this costs nothing at startup.
[ -f "$DOTFILES/zsh/extra/autols.zsh" ] && source "$DOTFILES/zsh/extra/autols.zsh"

#------------------------------------------------------------------------------
# Tool integrations
#------------------------------------------------------------------------------
# All of these print a static zsh integration on stdout; zcache sources it from
# disk instead of forking the tool on every start. See zsh/extra/cache.zsh.

# zoxide — smarter `cd` (provides `z` and `zi`)
zcache zoxide zoxide init zsh

# atuin — shell history (owns Ctrl-R / Up). Initialised exactly once.
[ -f "$HOME/.atuin/bin/env" ] && . "$HOME/.atuin/bin/env"
zcache atuin atuin init zsh

# navi — interactive cheatsheets (Ctrl-G)
zcache navi navi widget zsh

# pay-respects — corrects the last failed command (replaces thefuck, whose repo
# is dead and which spawned a Python interpreter on every invocation). Kept on
# `fuck` for muscle memory; the binary's own default is `f`, which would collide
# with our fzf alias. Also binds ^X^X to fix the current line in place.
#
# --nocnf is REQUIRED, not cosmetic: without it pay-respects installs its own
# command_not_found_handler, which does typo-correction but knows nothing about
# Homebrew (no brew/formula lookup in the binary at all) and would silently
# shadow the brew handler below — losing "install it with brew install X".
#
# NB: the --alias/--nocnf arguments are baked into the cached output. If they
# ever change, run `zcache_clear` — mtime invalidation only catches a new binary.
zcache pay-respects pay-respects zsh --alias fuck --nocnf

# Homebrew command-not-found — when an unknown command is typed, suggest the
# formula that provides it (`brew which-formula` under the hood). Shipped in
# Homebrew core now (the old homebrew/command-not-found tap was deprecated).
# Source the handler directly rather than `eval "$(brew command-not-found-init)"`
# so we don't spawn brew on every startup; $HOMEBREW_REPOSITORY is exported by
# .zprofile. With --nocnf above, this is the only handler defined — but keep it
# last anyway so it wins if that flag is ever dropped.
() {
  local h="${HOMEBREW_REPOSITORY:-/opt/homebrew}/Library/Homebrew/command-not-found/handler.sh"
  [[ -r $h ]] && source "$h"
}

#------------------------------------------------------------------------------
# Colors — everything on Voltage
#------------------------------------------------------------------------------
# This repo's own palette; the canonical values and the full list of files that
# carry it are in themes/voltage.md. It is set in six places, and all six have
# to agree or the shell looks patched together: the terminal itself
# (.config/ghostty/config), vivid (LS_COLORS, above), starship
# (.config/starship.toml), fzf (zsh/extra/fzf.zsh) and the two below.

# bat's theme. This also themes delta, which has no syntax theme of its own —
# it renders through bat's highlighting engine and reads $BAT_THEME when
# --syntax-theme isn't passed. delta is used by the git-diff/git-show fzf-tab
# previews above, so this is what makes those previews match everything else.
#
# Unlike the built-in themes, "Voltage" is ours (.config/bat/themes/
# Voltage.tmTheme) and only exists once `bat cache --build` has run — install.sh
# does that. If bat ever falls back to its default theme, that build is why.
export BAT_THEME="Voltage"

# eza's colors. Note this is EZA_COLORS, not EXA_COLORS: the latter is from the
# pre-rename exa days and eza does not read it. The dead .config/exa/EXA_COLORS
# that used to sit alongside this comment has been removed — install.sh links
# every .config/* entry, so keeping it meant planting a dead symlink in
# ~/.config on every machine.
#
# eza reads LS_COLORS too (set above), so this only overrides what LS_COLORS
# has no opinion on: the permission bits, ownership and size columns that
# `l`/`ll`/`la` show. Without it those columns render in default white and the
# long listing is a wall of grey with only the filenames colored.
#
# Voltage, as 24-bit SGR (eza takes no hex here): read = green #b3e053,
# write = red #ff4d5e, execute = blue #5cc9f5, setuid/setgid = magenta
# #eb43f4, size = yellow #fcf58d, date/xattr = cyan #17d5df, names =
# fg #e7e7e7, absent = subtle #6b6b6b.
export EZA_COLORS="ur=38;2;179;224;83:uw=38;2;255;77;94:ux=38;2;92;201;245:ue=38;2;92;201;245:gr=38;2;179;224;83:gw=38;2;255;77;94:gx=38;2;92;201;245:tr=38;2;179;224;83:tw=38;2;255;77;94:tx=38;2;92;201;245:su=38;2;235;67;244:sf=38;2;235;67;244:xa=38;2;23;213;223:sn=38;2;252;245;141:sb=38;2;252;245;141:uu=38;2;231;231;231:un=38;2;107;107;107:gu=38;2;231;231;231:gn=38;2;107;107;107:da=38;2;23;213;223:xx=38;2;107;107;107"

# zsh-autosuggestions: async fetch
export ZSH_AUTOSUGGEST_USE_ASYNC=true

# zsh-autosuggestions: the inline ghost text. The plugin default is 8 (dim
# grey), which on a bright palette reads as a rendering artifact rather than a
# suggestion. Voltage's `subtle`, stated as truecolor so it doesn't depend on
# how the terminal maps ANSI 8.
export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#6b6b6b"

# tabtab completions (serverless, etc.)
[[ -f ~/.config/tabtab/zsh/__tabtab.zsh ]] && . ~/.config/tabtab/zsh/__tabtab.zsh || true

#------------------------------------------------------------------------------
# Byte-compile the config
#------------------------------------------------------------------------------
# zsh parses these ~850 lines from source on every start unless a .zwc sits
# next to each file — `source` (and zsh's own startup-file loading) prefers a
# .zwc that is newer than its source, transparently.
#
# Done last, and cheaply: this is a stat per file, and it only writes when a
# file has actually changed. A recompile therefore costs nothing on a normal
# start, and an edit is picked up automatically on the *next* shell — no manual
# `zcompile` step to forget after editing a dotfile.
#
# zcompile -R (rather than -M) maps the file eagerly, which is what we want for
# files this small: no mmap bookkeeping for a few KB.
() {
  local f
  for f in \
    ${ZDOTDIR:-$HOME}/.zshenv \
    ${ZDOTDIR:-$HOME}/.zprofile \
    ${ZDOTDIR:-$HOME}/.zshrc \
    $DOTFILES/zsh/zinit.zsh \
    $DOTFILES/zsh/functions.zsh \
    $DOTFILES/zsh/aliases.zsh \
    $DOTFILES/zsh/extra/*.zsh(N)
  do
    # -nt follows symlinks, so the $HOME/.zshrc → dotfiles/.zshrc links compare
    # against the real file's mtime and recompile when the repo copy is edited.
    [[ -s $f && ( ! -s $f.zwc || $f -nt $f.zwc ) ]] && zcompile -R -- $f 2>/dev/null
  done
  return 0
}


