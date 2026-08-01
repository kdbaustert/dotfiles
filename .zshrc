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
# Plugins (zinit) — loads prompt, completions, autosuggestions, highlighting
#------------------------------------------------------------------------------
[ -f "$DOTFILES/zsh/zinit.zsh" ] && source "$DOTFILES/zsh/zinit.zsh"

#------------------------------------------------------------------------------
# Completion styling
#------------------------------------------------------------------------------
source "$DOTFILES/zsh/extra/completion.zsh"

# LS_COLORS via vivid — colorizes the completion menu (and fzf-tab previews).
command -v vivid &>/dev/null && export LS_COLORS="$(vivid generate catppuccin-mocha)"
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
command -v fzf &>/dev/null && source <(fzf --zsh)

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

#------------------------------------------------------------------------------
# Tool integrations
#------------------------------------------------------------------------------
# zoxide — smarter `cd` (provides `z` and `zi`)
command -v zoxide &>/dev/null && eval "$(zoxide init zsh)"

# atuin — shell history (owns Ctrl-R / Up). Initialised exactly once.
[ -f "$HOME/.atuin/bin/env" ] && . "$HOME/.atuin/bin/env"
command -v atuin &>/dev/null && eval "$(atuin init zsh)"

# navi — interactive cheatsheets (Ctrl-G)
command -v navi &>/dev/null && eval "$(navi widget zsh)"

# pay-respects — corrects the last failed command (replaces thefuck, whose repo
# is dead and which spawned a Python interpreter on every invocation). Kept on
# `fuck` for muscle memory; the binary's own default is `f`, which would collide
# with our fzf alias. Also binds ^X^X to fix the current line in place.
#
# --nocnf is REQUIRED, not cosmetic: without it pay-respects installs its own
# command_not_found_handler, which does typo-correction but knows nothing about
# Homebrew (no brew/formula lookup in the binary at all) and would silently
# shadow the brew handler below — losing "install it with brew install X".
# Cheap enough (<1ms Rust binary) to init eagerly; no lazy wrapper needed.
command -v pay-respects &>/dev/null && eval "$(pay-respects zsh --alias fuck --nocnf)"

# Homebrew command-not-found — when an unknown command is typed, suggest the
# formula that provides it (`brew which-formula` under the hood). Shipped in
# Homebrew core now (the old homebrew/command-not-found tap was deprecated).
# Source the handler directly rather than `eval "$(brew command-not-found-init)"`
# so we don't spawn brew on every startup; $HOMEBREW_REPOSITORY comes from
# brew shellenv in .zprofile. With --nocnf above, this is the only handler
# defined — but keep it last anyway so it wins if that flag is ever dropped.
() {
  local h="${HOMEBREW_REPOSITORY:-/opt/homebrew}/Library/Homebrew/command-not-found/handler.sh"
  [[ -r $h ]] && source "$h"
}

# zsh-autosuggestions: async fetch
export ZSH_AUTOSUGGEST_USE_ASYNC=true

# tabtab completions (serverless, etc.)
[[ -f ~/.config/tabtab/zsh/__tabtab.zsh ]] && . ~/.config/tabtab/zsh/__tabtab.zsh || true