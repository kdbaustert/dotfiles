#!/usr/bin/env zsh

# Created by Kenny B <kenny@gothamx.dev>

if [ -d "$HOME/.nvm" ]; then
	export NVM_DIR="$HOME/.nvm"
fi

if [ -d "$HOME/.composer/vendor/bin" ]; then
	export PATH="$HOME/.composer/vendor/bin:$PATH"
fi

if [ -d "$HOME/.config/composer/vendor/bin" ]; then
	PATH="$HOME/.config/composer/vendor/bin:$PATH"
fi

[[ -f "$DOTFILES/zsh/zinit.zsh" ]] && source "$DOTFILES/zsh/zinit.zsh"

[[ -f "$DOTFILES/zsh/completion.zsh" ]] && source "$DOTFILES/zsh/completion.zsh"

# Delete % at the beginning
unsetopt PROMPT_SP

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

# FZF custom Aura theme
export FZF_DEFAULT_OPTS=$FZF_DEFAULT_OPTS'
--reverse
--color=fg:-1,bg:-1,border:#4B5164,hl:#d19a66
--color=fg+:#a6accd,bg+:#2c323d,hl+:#e5c07b
--color=info:#ffcb6b,prompt:#82e2ff,pointer:#c792ea
--color=marker:#ffcb6b,spinner:#e06c75,header:#a277ff'
# FZF options for zoxide prompt (zi)
export _ZO_FZF_OPTS=$FZF_DEFAULT_OPTS'
--height=45%'

export FZF_COMPLETION_TRIGGER=','

# ------------------------------------
# Fuzzy Finder
# ------------------------------------

export FZF_DEFAULT_COMMAND='fd --exclude .git --max-depth 5 --hidden'
export FZF_COMPLETION_TRIGGER=','

bindkey -e
bindkey \^U backward-kill-line

# FUNCTIONS
[[ -f $DOTFILES/zsh/functions.zsh ]] && source $DOTFILES/zsh/functions.zsh

# ALIASES
[[ -f $DOTFILES/zsh/aliases.zsh ]] && source $DOTFILES/zsh/aliases.zsh

source /opt/homebrew/opt/asdf/asdf.sh

nvim() {
	unset -f nvim
	_zsh_nvm_load
	nvim "$@"
}

echo -e -n "\x1b[\x30 q"

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"
