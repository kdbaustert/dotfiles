#!/usr/bin/env zsh
#==============================================================================
#  .zshrc — interactive shell configuration
#  Login/environment setup lives in .zprofile; this file is interactive-only.
#==============================================================================

# Kiro CLI pre block. Keep at the top of this file.
[[ -f "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.pre.zsh" ]] && builtin source "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.pre.zsh"

# $DOTFILES is normally exported by .zprofile, but that only runs for login
# shells. Fall back to the default so this file works in non-login shells too.
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
setopt HIST_VERIFY             # expand history, but let me confirm before running
setopt INC_APPEND_HISTORY      # append as commands run, not at shell exit
setopt SHARE_HISTORY           # share history live across sessions

#------------------------------------------------------------------------------
# Shell options
#------------------------------------------------------------------------------
setopt AUTOCD                  # `dir` == `cd dir`
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

#------------------------------------------------------------------------------
# Tool integrations
#------------------------------------------------------------------------------
# zoxide — smarter `cd` (provides `z` and `zi`)
command -v zoxide &>/dev/null && eval "$(zoxide init zsh)"

# pyenv — Python version management. PYENV_ROOT is exported in .zprofile; the
# shell integration is loaded via zinit turbo (see zinit.zsh) so it doesn't
# block startup. Nothing to init synchronously here.

# atuin — shell history (owns Ctrl-R / Up). Initialised exactly once.
[ -f "$HOME/.atuin/bin/env" ] && . "$HOME/.atuin/bin/env"
command -v atuin &>/dev/null && eval "$(atuin init zsh)"

# navi — interactive cheatsheets (Ctrl-G)
command -v navi &>/dev/null && eval "$(navi widget zsh)"

# thefuck — lazy-loaded so it doesn't spawn Python on every shell start
fuck() { unset -f fuck; eval "$(thefuck --alias)"; fuck "$@"; }

# zsh-autosuggestions: async fetch
export ZSH_AUTOSUGGEST_USE_ASYNC=true

# tabtab completions (serverless, etc.)
[[ -f ~/.config/tabtab/zsh/__tabtab.zsh ]] && . ~/.config/tabtab/zsh/__tabtab.zsh || true

# Emit OSC 7 so terminals (e.g. Rio) can open new tabs in the current directory
_osc7_cwd() { printf '\e]7;file://%s%s\e\\' "$HOST" "$PWD"; }
autoload -Uz add-zsh-hook
add-zsh-hook chpwd _osc7_cwd
_osc7_cwd

# Kiro CLI post block. Keep at the bottom of this file.
[[ -f "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.post.zsh" ]] && builtin source "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.post.zsh"
export PATH="${HOME}/Library/FlyEnv/alias:${HOME}/Library/FlyEnv/env/php/bin:${HOME}/Library/FlyEnv/env/php:$PATH"
# pnpm
export PNPM_HOME="${HOME}/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME/bin:"*) ;;
  *) export PATH="$PNPM_HOME/bin:$PATH" ;;
esac
# pnpm end
