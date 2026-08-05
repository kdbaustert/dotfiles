#!/usr/bin/env zsh


#==============================================================================
#  .zshrc — interactive shell configuration
#  Login/environment setup lives in .zprofile; this file is interactive-only.
#==============================================================================

# $DOTFILES is exported by .zshenv (sourced for every zsh). Keep a defensive
# fallback in case this file is ever sourced without it.
: "${DOTFILES:=$HOME/dotfiles}"

#------------------------------------------------------------------------------
# iris — autostart (deliberately above everything expensive)
#------------------------------------------------------------------------------
# iris is a TTY wrapper, not a plugin: it replaces this shell with itself and
# spawns a fresh zsh inside, which sources this file again with $IRIS_PID set.
# Everything the outer shell did before the exec is discarded, so this block
# sits above cache.zsh/starship/zinit/fzf/atuin — anywhere lower and every
# terminal pays that startup cost twice. The ZLE plumbing for the inner shell
# is further down.
#
# Guards: IRIS_OFF=1 opts a single shell out; IRIS_RESCUE is set by iris itself
# when it catches a panic, writes ~/.iris/crash.log and re-execs $SHELL, so a
# bad build lands you at a plain prompt instead of a dead terminal; IRIS_PID
# means we're already the inner shell; the tty test keeps non-interactive
# oddities (a zsh sourced into a pipe) out of the wrapper.
#
# The tmux clause is verbatim from `iris init zsh`: a new pane inherits IRIS_PID
# from the server environment without actually being inside that iris, so clear
# it and let the pane start its own.
if [[ -n $TMUX && -n $IRIS_PID ]]; then
  [[ $(ps -o comm= -p $PPID 2>/dev/null) == *tmux* ]] && unset IRIS_PID IRIS_IS_CHILD IRIS_FD
fi

if [[ -z $IRIS_PID && -z $IRIS_RESCUE && -z $IRIS_OFF ]] && [[ -t 0 && -t 1 ]] \
   && command -v iris &>/dev/null; then
  export IRIS_ACTIVE_SHELL="zsh"
  exec iris
fi

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
zcache starship starship init zsh

#------------------------------------------------------------------------------
# Syntax-highlighting theme location
#------------------------------------------------------------------------------
# fast-syntax-highlighting's state dir. Must be set BEFORE zinit loads the
# plugin below, because the plugin reads it at source time and defaults it to
# ${XDG_CACHE_HOME:-~/.cache}/fast-syntax-highlighting — a cache dir, i.e. not
# in this repo and not reproducible on a new machine. Pointing it here is what
# makes .config/fsh/current_theme.zsh (the applied Snazzy theme, generated from
# snazzy.ini by `fast-theme XDG:snazzy`) load automatically on every box.
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
# Cached: vivid re-generates the same ~2KB string every start otherwise. Change
# the theme here and run `zcache_clear` — mtime invalidation only sees a new
# vivid binary, not new arguments.
zcache_value vivid-ls-colors LS_COLORS vivid generate snazzy
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# fzf-tab tweaks
zstyle ':completion:*:git-checkout:*' sort false           # keep git ref order
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':fzf-tab:*' switch-group ',' '.'                   # cycle groups with , / .

# fzf-tab previews — show context for the candidate under the cursor
zstyle ':fzf-tab:complete:cd:*'                fzf-preview 'eza -1 --color=always --icons $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*'        fzf-preview 'eza -1 --color=always --icons $realpath'

# Command position (incl. aliases/functions): show what the candidate resolves
# to — `command -V` prints "x is an alias for …" / "… is a shell function" / path.
zstyle ':fzf-tab:complete:-command-:*'         fzf-preview 'command -V $word 2>/dev/null | head -20 || echo $word'
zstyle ':fzf-tab:complete:-command-:*'         fzf-flags '--preview-window=down:3:wrap'
zstyle ':fzf-tab:complete:(cat|bat|less|nvim|vim|vi|nano):*' \
                                               fzf-preview 'bat --color=always --style=numbers --line-range=:200 $realpath 2>/dev/null || eza -1 --color=always $realpath'
zstyle ':fzf-tab:complete:(-command-|export|unset):*' \
                                               fzf-preview 'echo ${(P)word}'        # env-var values
zstyle ':fzf-tab:complete:(kill|ps):argument-rest:*' \
                                               fzf-preview 'ps -p $word -o comm= -o args 2>/dev/null'
zstyle ':fzf-tab:complete:(kill|ps):argument-rest:*' fzf-flags '--preview-window=down:3:wrap'
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
# Colors — everything on Snazzy
#------------------------------------------------------------------------------
# The palette is set in four places, and all four have to agree or the shell
# looks patched together: vivid (LS_COLORS, above), starship (.config/
# starship.toml), fzf (zsh/extra/fzf.zsh) and the two below.

# bat's theme. This also themes delta, which has no syntax theme of its own —
# it renders through bat's highlighting engine and reads $BAT_THEME when
# --syntax-theme isn't passed. delta is used by the git-diff/git-show fzf-tab
# previews above, so this is what makes those previews match everything else.
# "Sublime Snazzy" ships with bat; no theme file or `bat cache --build` needed.
export BAT_THEME="Sublime Snazzy"

# eza's colors. Note this is EZA_COLORS, not the EXA_COLORS in
# .config/exa/EXA_COLORS — that file is from the pre-rename exa days, is
# sourced by nothing, and eza does not read it. Left in place, but it is dead.
#
# eza reads LS_COLORS too (set above), so this only overrides what LS_COLORS
# has no opinion on: the permission bits, ownership and size columns that
# `l`/`ll`/`la` show. Without it those columns render in default white and the
# long listing is a wall of grey with only the filenames colored.
export EZA_COLORS="ur=38;2;90;247;142:uw=38;2;255;92;87:ux=38;2;87;199;255:ue=38;2;87;199;255:gr=38;2;90;247;142:gw=38;2;255;92;87:gx=38;2;87;199;255:tr=38;2;90;247;142:tw=38;2;255;92;87:tx=38;2;87;199;255:su=38;2;255;106;193:sf=38;2;255;106;193:xa=38;2;154;237;254:sn=38;2;243;249;157:sb=38;2;243;249;157:uu=38;2;239;240;235:un=38;2;104;104;104:gu=38;2;239;240;235:gn=38;2;104;104;104:da=38;2;154;237;254:xx=38;2;104;104;104"

# zsh-autosuggestions: async fetch
export ZSH_AUTOSUGGEST_USE_ASYNC=true

# zsh-autosuggestions: the inline ghost text. The plugin default is 8 (dim
# grey), which on a bright palette reads as a rendering artifact rather than a
# suggestion. Snazzy's grey, stated as truecolor so it doesn't depend on how
# the terminal maps ANSI 8.
export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#686868"

# tabtab completions (serverless, etc.)
[[ -f ~/.config/tabtab/zsh/__tabtab.zsh ]] && . ~/.config/tabtab/zsh/__tabtab.zsh || true

# iris — IntelliSense-style completion menu (the Fig replacement). Autostarted
# from the block at the top of this file; this is the other half of
# `iris init zsh` — the ZLE plumbing the inner shell uses to talk to the
# wrapper. $IRIS_FD is the pipe back to iris and only exists inside it, so a
# plain zsh (IRIS_OFF=1, rescue shell, ssh to a box without iris) skips this
# entirely. It lives here rather than up top because it must load after
# zsh-autosuggestions has installed its own ZLE widgets.
#
# line-pre-redraw ships the buffer on every keystroke; chpwd/precmd ship $PWD.
# The cwd hooks are what make path suggestions resolve against the directory
# you're actually in — iris' file generator reads the shell-reported cwd, not
# its own getcwd, so without them `cd s…` would complete against wherever the
# wrapper was launched.
#
# Key conflicts are handled in ~/.config/iris/config.toml, not here: iris
# swallows its own keys before ZLE sees them, so its defaults are remapped off
# ctrl+r/up (atuin) and tab (fzf-tab), and ghost-text is off so it doesn't
# overprint zsh-autosuggestions.
#
# The `true >&$IRIS_FD` probe is an addition to what `iris init zsh` emits, and
# it matters: iris exports IRIS_PID/IRIS_FD into every process it starts, so a
# GUI app or long-running program launched from inside iris passes them on to
# whatever shells *it* spawns — shells that are not inside iris and where fd 13
# is closed or, worse, has been reused for something unrelated. Upstream would
# install the hooks anyway and print keystrokes at that fd. Probing it first
# means the hooks only load where the pipe is genuinely live.
if [[ -n $IRIS_PID && -n $IRIS_FD ]] && { true >&$IRIS_FD } 2>/dev/null; then
  _iris_send_lbuffer() { print -u $IRIS_FD -N -r -- "$LBUFFER" 2>/dev/null }
  _iris_sync_cwd()     { print -u $IRIS_FD -N -r -- "IRIS_CWD:$PWD" 2>/dev/null }
  _iris_preexec()      { print -u $IRIS_FD -N -r -- "IRIS_CMD_START" 2>/dev/null }
  _iris_precmd() {
    local iris_exit_code=$?
    _iris_sync_cwd
    print -u $IRIS_FD -N -r -- "IRIS_CMD_STOP:$iris_exit_code" 2>/dev/null
  }

  autoload -Uz add-zle-hook-widget
  autoload -Uz add-zsh-hook
  add-zle-hook-widget line-pre-redraw _iris_send_lbuffer
  add-zsh-hook precmd  _iris_precmd
  add-zsh-hook preexec _iris_preexec
  add-zsh-hook chpwd   _iris_sync_cwd
fi

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


