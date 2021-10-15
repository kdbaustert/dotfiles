#!/usr/bin/env zsh
# # disrupted zshrc

# # Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# # Initialization code that may require console input (password prompts, [y/n]
# # confirmations, etc.) must go above this block; everything else may go below.
# if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
#   source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
# fi

# Created by Kenny B <kenny@gothamx.dev>

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
export SHELL='/opt/homebrew/bin/zsh'
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

up-line-or-local-history() {
  zle set-local-history 1
  zle up-line-or-history
  zle set-local-history 0
}
zle -N up-line-or-local-history
down-line-or-local-history() {
  zle set-local-history 1
  zle down-line-or-history
  zle set-local-history 0
}
zle -N down-line-or-local-history

# Global history
bindkey "^[[1;5A" up-line-or-history   # [CTRL] + Cursor up
bindkey "^[[1;5B" down-line-or-history # [CTRL] + Cursor down

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# FUNCTIONS
[[ -f $DOTFILES/zsh/functions.zsh ]] && source $DOTFILES/zsh/functions.zsh

# ALIASES
[[ -f $DOTFILES/zsh/aliases.zsh ]] && source $DOTFILES/zsh/aliases.zsh

eval "$(zoxide init zsh)"

eval "$(mcfly init zsh)"

#####################
# FZF SETTINGS      #
#####################
# export FZF_DEFAULT_COMMAND='fd --files --no-ignore --hidden --follow -g "!{.git,node_modules}/*" 2>/dev/null'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_CTRL_T_OPTS='--preview="bat --color=always --style=header {} 2>/dev/null" --preview-window=right:60%:wrap'
export FZF_ALT_C_COMMAND='fd -t d -d 1'
export FZF_ALT_C_OPTS='--preview="exa -1 --icons --git --git-ignore {}" --preview-window=right:60%:wrap'
bindkey '^F' fzf-file-widget
# FZF custom OneDark theme
export FZF_DEFAULT_OPTS=$FZF_DEFAULT_OPTS'
--ansi
--color=fg:-1,bg:-1,border:#4B5164,hl:#d19a66
--color=fg+:#a6accd,bg+:#2c323d,hl+:#e5c07b
--color=info:#ffcb6b,prompt:#7982B4,pointer:#c792ea
--color=marker:#ffcb6b,spinner:#e06c75,header:#98c379'
# FZF options for zoxide prompt (zi)
export _ZO_FZF_OPTS=$FZF_DEFAULT_OPTS'
--height=10'

# alias preview="fzf --preview 'bat --color \"always\" {}'"
# export FZF_DEFAULT_OPTS="
# --bind='ctrl-o:execute(nvim {})+abort'
# --inline-info
# --color=spinner:#c594c5,hl:#82aaff
# --color=fg:#a6accd,header:#7982B4,info:#ffcb6b,pointer:#c792ea
# --color=marker:#ffcb6b,fg+:#a6accd,prompt:#c792ea,hl+:#c792ea
# "

[[ -f $DOTFILES/zsh/.p10k.zsh ]] && source $DOTFILES/zsh/.p10k.zsh

[[ -f $DOTFILES/zsh/aliases.zsh ]] && source $DOTFILES/zsh/aliases.zsh

s=' ' # fix too wide icons
POWERLEVEL9K_MODE="nerdfont-complete"
POWERLEVEL9K_APPLE_ICON=
POWERLEVEL9K_SHORTEN_STRATEGY=truncate_beginning
POWERLEVEL9K_PROMPT_ADD_NEWLINE=true
POWERLEVEL9K_PROMPT_ON_NEWLINE=true
POWERLEVEL9K_RPROMPT_ON_NEWLINE=false

POWERLEVEL9K_SHORTEN_DIR_LENGTH=2
POWERLEVEL9K_ICON_BEFORE_CONTENT=true
POWERLEVEL9K_OS_ICON_CONTENT_EXPANSION='${P9K_CONTENT} $(whoami | grep -v "^root\$")'
POWERLEVEL9K_OS_ICON_BACKGROUND=#8d36fe
POWERLEVEL9K_OS_ICON_FOREGROUND=#fff
POWERLEVEL9K_ROOT_INDICATOR_BACKGROUND=black
POWERLEVEL9K_ROOT_INDICATOR_FOREGROUND=red

POWERLEVEL9K_SSH_BACKGROUND=white
POWERLEVEL9K_SSH_FOREGROUND=blue
POWERLEVEL9K_FOLDER_ICON=

POWERLEVEL9K_DIR_BACKGROUND=cyan
POWERLEVEL9K_DIR_FOREGROUND=black
POWERLEVEL9K_DIR_WRITABLE_BACKGROUND=white
POWERLEVEL9K_DIR_WRITABLE_FOREGROUND=red

POWERLEVEL9K_VCS_CLEAN_FOREGROUND='white'
POWERLEVEL9K_VCS_CLEAN_BACKGROUND='yellow'
POWERLEVEL9K_VCS_UNTRACKED_FOREGROUND='red'
POWERLEVEL9K_VCS_UNTRACKED_BACKGROUND='green'
POWERLEVEL9K_VCS_MODIFIED_FOREGROUND='black'
POWERLEVEL9K_VCS_MODIFIED_BACKGROUND='blue'
POWERLEVEL9K_VCS_UNTRACKED_ICON=●
POWERLEVEL9K_VCS_UNSTAGED_ICON=±
POWERLEVEL9K_VCS_INCOMING_CHANGES_ICON=↓
POWERLEVEL9K_VCS_OUTGOING_CHANGES_ICON=↑
POWERLEVEL9K_VCS_COMMIT_ICON=$s

POWERLEVEL9K_STATUS_VERBOSE=false
POWERLEVEL9K_STATUS_VERBOSE=false
POWERLEVEL9K_STATUS_OK_IN_NON_VERBOSE=true

POWERLEVEL9K_EXECUTION_TIME_ICON=$s

POWERLEVEL9K_COMMAND_EXECUTION_TIME_THRESHOLD=0
POWERLEVEL9K_COMMAND_EXECUTION_TIME_BACKGROUND=black
POWERLEVEL9K_COMMAND_EXECUTION_TIME_FOREGROUND=blue
POWERLEVEL9K_COMMAND_BACKGROUND_JOBS_BACKGROUND=black
POWERLEVEL9K_COMMAND_BACKGROUND_JOBS_FOREGROUND=cyan

POWERLEVEL9K_TIME_ICON=
POWERLEVEL9K_TIME_FORMAT='%D{%I:%M}'
POWERLEVEL9K_TIME_BACKGROUND=black
POWERLEVEL9K_TIME_FOREGROUND=white

POWERLEVEL9K_RAM_ICON=
POWERLEVEL9K_RAM_FOREGROUND=black
POWERLEVEL9K_RAM_BACKGROUND=cyan

POWERLEVEL9K_VI_MODE_FOREGROUND=black
POWERLEVEL9K_VI_COMMAND_MODE_STRING=NORMAL
POWERLEVEL9K_VI_MODE_NORMAL_BACKGROUND=green
POWERLEVEL9K_VI_VISUAL_MODE_STRING=VISUAL
POWERLEVEL9K_VI_MODE_VISUAL_BACKGROUND=blue
POWERLEVEL9K_VI_OVERWRITE_MODE_STRING=OVERTYPE
POWERLEVEL9K_VI_MODE_OVERWRITE_BACKGROUND=red
POWERLEVEL9K_VI_INSERT_MODE_STRING=

POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX='%F{blue}╭─'
POWERLEVEL9K_MULTILINE_LAST_PROMPT_PREFIX='%F{blue}╰%f '
POWERLEVEL9K_MULTILINE_FIRST_PROMPT_SUFFIX='%F{blue}─╮'
POWERLEVEL9K_MULTILINE_LAST_PROMPT_SUFFIX='%F{blue}─╯'
ZLE_RPROMPT_INDENT=0

POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(
  os_icon
  root_indicator
  ssh
  dir
  dir_writable
  vcs
)

POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(
  status
  command_execution_time
  ram
)

. /usr/local/opt/asdf/libexec/asdf.sh

if [ -e /Users/kenny/.nix-profile/etc/profile.d/nix.sh ]; then . /Users/kenny/.nix-profile/etc/profile.d/nix.sh; fi # added by Nix installer
