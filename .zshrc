#!/usr/bin/env zsh

# Created by Kenny B <kenny@gothamx.dev>

# Disaable compfix warning
ZSH_DISABLE_COMPFIX=true

# Remove percent sign at the beginning
# https://superuser.com/questions/645599/why-is-a-percent-sign-appearing-before-each-prompt-on-zsh-in-windows
unsetopt PROMPT_SP

####################
# ENV VARIABLE      #
#####################
export DOTFILES=$HOME/dotfiles
export LSCOLORS="Gxfxcxdxbxegedabagacad"
export EDITOR='nvim'
export VISUAL=$EDITOR
export PAGER='less'
export LESS='-F -g -i -M -R -S -w -X -z-4 -~'
export LESS_TERMCAP_mb=$'\E[6m'    # begin blinking
export LESS_TERMCAP_md=$'\E[34m'   # begin bold
export LESS_TERMCAP_us=$'\E[4;32m' # begin underline
export LESS_TERMCAP_so=$'\E[0m'    # begin standout-mode (info box), remove background
export LESS_TERMCAP_me=$'\E[0m'    # end mode
export LESS_TERMCAP_ue=$'\E[0m'    # end underline
export LESS_TERMCAP_se=$'\E[0m'    # end standout-mode
export MANPAGER="nvim -c 'set ft=man' -"
export LANG='en_US.UTF-8'
export LC_ALL='en_US.UTF-8'
export WORDCHARS='~!#$%^&*(){}[]<>?.+;' # sane moving between words on the prompt
export GPG_TTY=$(tty)
export PATH="/opt/homebrew/bin:$PATH"
export PATH="$PATH:~/.local/bin" # for pipx
export PATH="$PATH:$GOPATH/bin"
export PROMPT_EOL_MARK='' # hide % at end of output
export PATH="/usr/local/sbin:$PATH"

if [ -d "$HOME/.nvm" ]; then
  export NVM_DIR="$HOME/.nvm"
fi

if [ -d "$HOME/.composer/vendor/bin" ]; then
  export PATH="$HOME/.composer/vendor/bin:$PATH"
fi

[[ -f "$DOTFILES/zsh/zinit.zsh" ]] && source "$DOTFILES/zsh/zinit.zsh"

[[ -f "$DOTFILES/zsh/completion.zsh" ]] && source "$DOTFILES/zsh/completion.zsh"

#####################
# HISTORY           #
#####################
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000000
SAVEHIST=10000000

#####################
# SETOPT            #
#####################
setopt EXTENDED_HISTORY       # record timestamp of command in HISTFILE
setopt HIST_EXPIRE_DUPS_FIRST # delete duplicates first when HISTFILE size exceeds HISTSIZE
setopt HIST_IGNORE_ALL_DUPS   # ignore duplicated commands history list
setopt SHARE_HISTORY          # share command history data
setopt HIST_IGNORE_SPACE      # ignore commands that start with space
setopt SHAREHISTORY           # global history
setopt HIST_VERIFY            # show command with history expansion to user before running it
setopt INC_APPEND_HISTORY     # add commands to HISTFILE in order of execution
setopt COMPLETEALIASES        # complete alisases
setopt NOCORRECT              # spelling correction for commands
setopt COMPLETE_IN_WORD       # allow completion from within a word/phrase
setopt LIST_AMBIGUOUS         # complete as much of a completion until it gets ambiguous.
setopt HASH_LIST_ALL          # hash everything before completion
setopt GLOB_DOTS              # no special treatment for file names with a leading dot
setopt NO_AUTO_MENU           # require an extra TAB press to open the completion menu
setopt NOTIFY                 # Report the status of background jobs immediately, rather than waiting until just before printing a prompt.
setopt NO_BG_NICE             # Prevent runing all background jobs at a lower priority.
setopt NO_CHECK_JOBS          # Prevent reporting the status of background and suspended jobs before exiting a shell with job control. NO_CHECK_JOBS is best used only in combination with NO_HUP, else such jobs will be killed automatically.
setopt NO_HUP                 # Prevent sending the HUP signal to running jobs when the shell exits.
setopt NO_BEEP                # Don't beep on erros (overrides /etc/zshrc in Catalina)
setopt ALWAYS_TO_END          # If a completion is performed with the cursor within a word, and a full completion is inserted, the cursor is moved to the end of the word
setopt PATH_DIRS              # Perform a path search even on command names with slashes in them.
unsetopt CASE_GLOB            # Make globbing (filename generation) not sensitive to case.
unsetopt LIST_BEEP            # Don't beep on an ambiguous completion.
setopt NOLISTTYPES
setopt LISTPACKED
setopt AUTOMENU
setopt AUTOCD
setopt INTERACTIVECOMMENTS # recognize comments

autoload colors && colors

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

export FZF_DEFAULT_COMMAND='fd --exclude .git --max-depth 5 --hidden'

# FZF custom Aura theme
export FZF_DEFAULT_OPTS=$FZF_DEFAULT_OPTS'
--reverse
--color=fg:-1,bg:-1,border:#4B5164,hl:#d19a66
--color=fg+:#a6accd,bg+:#2c323d,hl+:#e5c07b
--color=info:#ffcb6b,prompt:#82e2ff,pointer:#c792ea
--color=marker:#ffcb6b,spinner:#e06c75,header:#a277ff'
# FZF options for zoxide prompt (zi)
export _ZO_FZF_OPTS=$FZF_DEFAULT_OPTS'
--height=40%'

export FZF_COMPLETION_TRIGGER=','

# ------------------------------------
# Fuzzy Finder
# ------------------------------------

export FZF_DEFAULT_COMMAND='fd --exclude .git --max-depth 5 --hidden'
# export FZF_DEFAULT_OPTS='--height 40% --reverse --border'
export FZF_COMPLETION_TRIGGER=','

function fzf-file() {
  local find_cmd='fd --exclude .git --max-depth 3 --hidden'
  local add_slash="awk '{print \$0 \"/\"}'"
  local preview_dir='exa --tree -L 2 {}'
  local preview_file='bat --style=header,grid --color=always --line-range :100 {}'
  local preview_cmd="if [[ {} == */ ]] ; then ${preview_dir}; else ${preview_file}; fi"
  local fzf_cmd="fzf -0 -1 --preview '${preview_cmd}'"
  local cmd="{${find_cmd} --type d | ${add_slash}; ${find_cmd} --type f} | ${fzf_cmd}"
  local ret=$(eval "${cmd}")
  case $ret in
    "")  zle reset-prompt && return;;
    */)  cd $ret ;;
    *)   ${EDITOR} $ret ;;
  esac
  zle accept-line
}

zle -N fzf-file
bindkey '^O' fzf-file

# disable sort when completing `git checkout`
zstyle ':completion:*:git-checkout:*' sort false
# set descriptions format to enable group support
zstyle ':completion:*:descriptions' format '[%d]'
# set list-colors to enable filename colorizing
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
# preview directory's content with exa when completing cd
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'exa -1 --color=always $realpath'
# switch group using `,` and `.`
zstyle ':fzf-tab:*' switch-group ',' '.'

# only for git
zstyle ':completion:*:*:git:*' fzf-search-display true
# or for everything
zstyle ':completion:*' fzf-search-display true

# basic file preview for ls (you can replace with something more sophisticated than head)
zstyle ':completion::*:ls::*' fzf-completion-opts --preview='eval head {1}'

# preview when completing env vars (note: only works for exported variables)
# eval twice, first to unescape the string, second to expand the $variable
zstyle ':completion::*:(-command-|-parameter-|-brace-parameter-|export|unset|expand):*' fzf-completion-opts --preview='eval eval echo {1}'

# preview a `git status` when completing git add
zstyle ':completion::*:git::git,add,*' fzf-completion-opts --preview='git -c color.status=always status --short'

# if other subcommand to git is given, show a git diff or git log
zstyle ':completion::*:git::*,[a-z]*' fzf-completion-opts --preview='
eval set -- {+1}
for arg in "$@"; do
    { git diff --color=always -- "$arg" | git log --color=always "$arg" } 2>/dev/null
done'

zstyle ':completion:*' completer _expand _complete _ignored _approximate
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*' menu select=2
zstyle ':completion:*' select-prompt '%SScrolling active: current selection at %p%s'
zstyle ':completion:*:descriptions' format '-- %d --'
zstyle ':completion:*:processes' command 'ps -au$USER'
zstyle ':completion:complete:*:options' sort false
zstyle ':fzf-tab:*' query-string prefix first
# zstyle ':fzf-tab:complete:_zlua:*' query-string input
zstyle ':fzf-tab:*' continuous-trigger '/'
zstyle ':completion:*:*:*:*:processes' command "ps -u $USER -o pid,user,comm,cmd -w -w"
zstyle ':fzf-tab:complete:kill:argument-rest' fzf-flags --preview=$extract'ps --pid=$in[(w)1] -o cmd --no-headers -w -w' --preview-window=down:3:wrap
# zstyle ':fzf-tab:complete:cd:*' fzf-preview 'exa -1 --color=always $realpath'  # disable for tmux-popup
zstyle ':fzf-tab:*' switch-group ',' '.'
zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup
zstyle ':fzf-tab:*' popup-pad 0 0
zstyle ':completion:*:git-checkout:*' sort false
zstyle ':completion:*:exa' file-sort modification
zstyle ':completion:*:exa' sort false

# FUNCTIONS
[[ -f $DOTFILES/zsh/functions.zsh ]] && source $DOTFILES/zsh/functions.zsh

# ALIASES
[[ -f $DOTFILES/zsh/aliases.zsh ]] && source $DOTFILES/zsh/aliases.zsh

. /usr/local/opt/asdf/libexec/asdf.sh

if [ -e /Users/kenny/.nix-profile/etc/profile.d/nix.sh ]; then . /Users/kenny/.nix-profile/etc/profile.d/nix.sh; fi # added by Nix installer
